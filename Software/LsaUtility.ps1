# PowerShell script to manage LSA rights using C# code.

# Define the C# code for LSA operations, which will be compiled in memory.
$csharpCode = @"
using System;
using System.Text;
using System.Runtime.InteropServices;

namespace SecPol.Utility
{
    public class LsaUtility
    {

        // Import the LSA functions

        [DllImport("advapi32.dll", PreserveSig = true)]
        private static extern uint LsaOpenPolicy(
            ref LSA_UNICODE_STRING SystemName,
            ref LSA_OBJECT_ATTRIBUTES ObjectAttributes,
            uint DesiredAccess,
            out IntPtr PolicyHandle
        );

        [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
        private static extern uint LsaAddAccountRights(
            IntPtr PolicyHandle,
            IntPtr AccountSid,
            LSA_UNICODE_STRING[] UserRights,
            int CountOfRights);

        [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
        private static extern uint LsaEnumerateAccountRights(
           IntPtr PolicyHandle,
           IntPtr AccountSid,
           out IntPtr UserRights,
           out ulong CountOfRights);


        [DllImport("advapi32")]
        public static extern void FreeSid(IntPtr pSid);

        [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true, PreserveSig = true)]
        private static extern bool LookupAccountName(
            string lpSystemName, string lpAccountName,
            IntPtr psid,
            ref uint cbsid,
            StringBuilder domainName, ref uint cbdomainLength, ref int use);

        [DllImport("advapi32.dll")]
        private static extern bool IsValidSid(IntPtr pSid);

        [DllImport("advapi32.dll")]
        private static extern long LsaClose(IntPtr ObjectHandle);

        [DllImport("kernel32.dll")]
        private static extern int GetLastError();

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern uint LsaNtStatusToWinError(uint status);

        // define the structures

        [StructLayout(LayoutKind.Sequential)]
        private struct LSA_UNICODE_STRING
        {
            public UInt16 Length;
            public UInt16 MaximumLength;
            public IntPtr Buffer;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct LSA_OBJECT_ATTRIBUTES
        {
            public int Length;
            public IntPtr RootDirectory;
            public LSA_UNICODE_STRING ObjectName;
            public UInt32 Attributes;
            public IntPtr SecurityDescriptor;
            public IntPtr SecurityQualityOfService;
        }

        private static string LSAUS2string(LSA_UNICODE_STRING lsaus)
        {
            char[] cvt = new char[lsaus.Length / UnicodeEncoding.CharSize];
            Marshal.Copy(lsaus.Buffer, cvt, 0, lsaus.Length / UnicodeEncoding.CharSize);
            return new string(cvt);
        }

        // enum all policies

        private enum LSA_AccessPolicy : long
        {
            POLICY_VIEW_LOCAL_INFORMATION = 0x00000001L,
            POLICY_VIEW_AUDIT_INFORMATION = 0x00000002L,
            POLICY_GET_PRIVATE_INFORMATION = 0x00000004L,
            POLICY_TRUST_ADMIN = 0x00000008L,
            POLICY_CREATE_ACCOUNT = 0x00000010L,
            POLICY_CREATE_SECRET = 0x00000020L,
            POLICY_CREATE_PRIVILEGE = 0x00000040L,
            POLICY_SET_DEFAULT_QUOTA_LIMITS = 0x00000080L,
            POLICY_SET_AUDIT_REQUIREMENTS = 0x00000100L,
            POLICY_AUDIT_LOG_ADMIN = 0x00000200L,
            POLICY_SERVER_ADMIN = 0x00000400L,
            POLICY_LOOKUP_NAMES = 0x00000800L,
            POLICY_NOTIFICATION = 0x00001000L
        }

        /// <summary>Adds a privilege to an account</summary>
        /// <param name="accountName">Name of an account - "domain\account" or only "account"</param>
        /// <param name="privilegeName">Name ofthe privilege</param>
        /// <returns>The windows error code returned by LsaAddAccountRights</returns>
        public static long SetRight(String accountName, String privilegeName)
        {
            long winErrorCode = 0; //contains the last error

            //pointer an size for the SID
            IntPtr sid = IntPtr.Zero;
            uint sidSize = 0;
            //StringBuilder and size for the domain name
            StringBuilder domainName = new StringBuilder();
            uint nameSize = 0;
            //account-type variable for lookup
            int accountType = 0;

            //get required buffer size
            LookupAccountName(String.Empty, accountName, sid, ref sidSize, domainName, ref nameSize, ref accountType);

            //allocate buffers
            domainName = new StringBuilder((int)nameSize);
            sid = Marshal.AllocHGlobal((int)sidSize);

            //lookup the SID for the account
            bool result = LookupAccountName(String.Empty, accountName, sid, ref sidSize, domainName, ref nameSize, ref accountType);

            if (!result)
            {
                winErrorCode = GetLastError();
            }
            else
            {

                //initialize an empty unicode-string
                LSA_UNICODE_STRING systemName = new LSA_UNICODE_STRING();
                //combine all policies
                uint access = (uint)(
                    LSA_AccessPolicy.POLICY_AUDIT_LOG_ADMIN |
                    LSA_AccessPolicy.POLICY_CREATE_ACCOUNT |
                    LSA_AccessPolicy.POLICY_CREATE_PRIVILEGE |
                    LSA_AccessPolicy.POLICY_CREATE_SECRET |
                    LSA_AccessPolicy.POLICY_GET_PRIVATE_INFORMATION |
                    LSA_AccessPolicy.POLICY_LOOKUP_NAMES |
                    LSA_AccessPolicy.POLICY_NOTIFICATION |
                    LSA_AccessPolicy.POLICY_SERVER_ADMIN |
                    LSA_AccessPolicy.POLICY_SET_AUDIT_REQUIREMENTS |
                    LSA_AccessPolicy.POLICY_SET_DEFAULT_QUOTA_LIMITS |
                    LSA_AccessPolicy.POLICY_TRUST_ADMIN |
                    LSA_AccessPolicy.POLICY_VIEW_AUDIT_INFORMATION |
                    LSA_AccessPolicy.POLICY_VIEW_LOCAL_INFORMATION
                    );
                //initialize a pointer for the policy handle
                IntPtr policyHandle = IntPtr.Zero;

                //these attributes are not used, but LsaOpenPolicy wants them to exists
                LSA_OBJECT_ATTRIBUTES ObjectAttributes = new LSA_OBJECT_ATTRIBUTES();
                ObjectAttributes.Length = 0;
                ObjectAttributes.RootDirectory = IntPtr.Zero;
                ObjectAttributes.Attributes = 0;
                ObjectAttributes.SecurityDescriptor = IntPtr.Zero;
                ObjectAttributes.SecurityQualityOfService = IntPtr.Zero;

                //get a policy handle
                uint resultPolicy = LsaOpenPolicy(ref systemName, ref ObjectAttributes, access, out policyHandle);
                winErrorCode = LsaNtStatusToWinError(resultPolicy);

                if (winErrorCode == 0)
                {
                    //Now that we have the SID an the policy,
                    //we can add rights to the account.

                    //initialize an unicode-string for the privilege name
                    LSA_UNICODE_STRING[] userRights = new LSA_UNICODE_STRING[1];
                    userRights[0] = new LSA_UNICODE_STRING();
                    userRights[0].Buffer = Marshal.StringToHGlobalUni(privilegeName);
                    userRights[0].Length = (UInt16)(privilegeName.Length * UnicodeEncoding.CharSize);
                    userRights[0].MaximumLength = (UInt16)((privilegeName.Length + 1) * UnicodeEncoding.CharSize);

                    //add the right to the account
                    uint res = LsaAddAccountRights(policyHandle, sid, userRights, 1);
                    winErrorCode = LsaNtStatusToWinError(res);
                    LsaClose(policyHandle);
                }
                FreeSid(sid);
            }

            return winErrorCode;
        }

        public static long CheckRight(string accountName, out string[] currentRights)
        {
            currentRights = null;
            long winErrorCode = 0; //contains the last error

            //pointer an size for the SID
            IntPtr sid = IntPtr.Zero;
            uint sidSize = 0;
            //StringBuilder and size for the domain name
            StringBuilder domainName = new StringBuilder();
            uint nameSize = 0;
            //account-type variable for lookup
            int accountType = 0;

            ulong rightCount = 0;

            //get required buffer size
            LookupAccountName(String.Empty, accountName, sid, ref sidSize, domainName, ref nameSize, ref accountType);

            //allocate buffers
            domainName = new StringBuilder((int)nameSize);
            sid = Marshal.AllocHGlobal((int)sidSize);

            //lookup the SID for the account
            bool result = LookupAccountName(String.Empty, accountName, sid, ref sidSize, domainName, ref nameSize, ref accountType);
            
            if (!result)
            {
                winErrorCode = GetLastError();
            }
            else
            {

                //initialize an empty unicode-string
                LSA_UNICODE_STRING systemName = new LSA_UNICODE_STRING();
                //combine all policies
                uint access = (uint)(
                    LSA_AccessPolicy.POLICY_AUDIT_LOG_ADMIN |
                    LSA_AccessPolicy.POLICY_CREATE_ACCOUNT |
                    LSA_AccessPolicy.POLICY_CREATE_PRIVILEGE |
                    LSA_AccessPolicy.POLICY_CREATE_SECRET |
                    LSA_AccessPolicy.POLICY_GET_PRIVATE_INFORMATION |
                    LSA_AccessPolicy.POLICY_LOOKUP_NAMES |
                    LSA_AccessPolicy.POLICY_NOTIFICATION |
                    LSA_AccessPolicy.POLICY_SERVER_ADMIN |
                    LSA_AccessPolicy.POLICY_SET_AUDIT_REQUIREMENTS |
                    LSA_AccessPolicy.POLICY_SET_DEFAULT_QUOTA_LIMITS |
                    LSA_AccessPolicy.POLICY_TRUST_ADMIN |
                    LSA_AccessPolicy.POLICY_VIEW_AUDIT_INFORMATION |
                    LSA_AccessPolicy.POLICY_VIEW_LOCAL_INFORMATION
                    );
                //initialize a pointer for the policy handle
                IntPtr policyHandle = IntPtr.Zero;

                //these attributes are not used, but LsaOpenPolicy wants them to exists
                LSA_OBJECT_ATTRIBUTES ObjectAttributes = new LSA_OBJECT_ATTRIBUTES();
                ObjectAttributes.Length = 0;
                ObjectAttributes.RootDirectory = IntPtr.Zero;
                ObjectAttributes.Attributes = 0;
                ObjectAttributes.SecurityDescriptor = IntPtr.Zero;
                ObjectAttributes.SecurityQualityOfService = IntPtr.Zero;

                //get a policy handle
                uint resultPolicy = LsaOpenPolicy(ref systemName, ref ObjectAttributes, access, out policyHandle);
                winErrorCode = LsaNtStatusToWinError(resultPolicy);

                if (winErrorCode == 0)
                {
                    //Now that we have the SID an the policy,
                    //we can add rights to the account.

                    //initialize an unicode-string for the privilege name
                    IntPtr userRights = IntPtr.Zero;

                    //add the right to the account
                    uint res = LsaEnumerateAccountRights(policyHandle, sid, out userRights, out rightCount);
                    winErrorCode = LsaNtStatusToWinError(res);
                    currentRights = new string[rightCount];

                    LSA_UNICODE_STRING myLsaus = new LSA_UNICODE_STRING();
                    for (ulong i = 0; i < rightCount; i++)
                    {
                        IntPtr itemAddr = new IntPtr(userRights.ToInt64() + (long)(i * (ulong)Marshal.SizeOf(myLsaus)));
                        myLsaus = (LSA_UNICODE_STRING)Marshal.PtrToStructure(itemAddr, myLsaus.GetType());
                        currentRights[i] = LSAUS2string(myLsaus);
                    }

                    LsaClose(policyHandle);
                }
                FreeSid(sid);
            }

            return winErrorCode;
        }
    }
}
"@

# Add the C# type to the PowerShell session.
# This makes the SecPol.Utility.LsaUtility class available.
Add-Type -TypeDefinition $csharpCode

function Set-Right {
    param(
        [Parameter(Mandatory=$true)]
        [string]$AccountName,

        [Parameter(Mandatory=$true)]
        [string]$PrivilegeName
    )

    $winErrorCode = [SecPol.Utility.LsaUtility]::SetRight($AccountName, $PrivilegeName)
    if ($winErrorCode -eq 0) {
        Write-Host "Successfully granted '$PrivilegeName' to '$AccountName'."
    }
    else {
        Write-Error "Failed to grant '$PrivilegeName' to '$AccountName'. Windows Error Code: $winErrorCode"
    }
}

function Check-Right {
    param(
        [Parameter(Mandatory=$true)]
        [string]$AccountName
    )

    $CurrentRights = $null
    $winErrorCode = [SecPol.Utility.LsaUtility]::CheckRight($AccountName, [ref]$CurrentRights)
    if ($winErrorCode -eq 0) {
        Write-Host "Successfully checked rights of '$AccountName'."
        foreach ($right in $CurrentRights) {
            Write-Host " - $right"
        }
    }
    else {
        Write-Host "Failed to check rights of '$AccountName'. Windows Error Code: $winErrorCode"
    }
}

<#
.SYNOPSIS
    Grants a privilege to a user account.

.DESCRIPTION
    This script defines a PowerShell function 'Set-Right' that uses a compiled C# class to interact with the Local Security Authority (LSA) API.
    This allows granting specific user rights (privileges) to local or domain user accounts.
    The script requires administrative privileges to run.

.EXAMPLE
    # To run this script, you must first dot-source it into your session:
    . .\LsaUtility.ps1

    # Then you can use the Set-Right function.
    # This example grants the "Log on as a service" right to the local "Administrator" account.
    Set-Right -AccountName "Administrator" -PrivilegeName "SeServiceLogonRight"

.EXAMPLE
    # This example grants the "Allow log on locally" right to a user named "TestUser".
    Set-Right -AccountName "TestUser" -PrivilegeName "SeInteractiveLogonRight"

.INPUTS
    None. You cannot pipe objects to this script.

.OUTPUTS
    None. This script does not generate any output to the pipeline. It writes messages to the host.
#>
