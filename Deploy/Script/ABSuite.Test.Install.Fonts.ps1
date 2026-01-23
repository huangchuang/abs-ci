param(
    [string]$font_dir
)

# Define the C# code for LSA operations, which will be compiled in memory.
$csharpCode = @"
using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace InstallFonts
{
    public class Program
    {
        [DllImport("gdi32", EntryPoint = "AddFontResource")]
        private static extern int AddFontResource(string lpszFilename);

        public static void Main(string[] args)
        {
            try
            {
                if (args.Length > 0 && Directory.Exists(args[0]))
                {
                    RegisterFont(args[0], "arial.TTF", "Arial");
                    RegisterFont(args[0], "arialbd.TTF", "Arial Bold");
                    RegisterFont(args[0], "arialbi.TTF", "Arial Bold Italic");
                    RegisterFont(args[0], "ariali.TTF", "Arial Italic");
                    RegisterFont(args[0], "ARIALN.TTF", "Arial Narrow");
                    RegisterFont(args[0], "ARIALNB.TTF", "Arial Narrow Bold");
                    RegisterFont(args[0], "ARIALNBI.TTF", "Arial Narrow Bold Italic");
                    RegisterFont(args[0], "ARIALNI.TTF", "Arial Narrow Italic");
                    RegisterFont(args[0], "ariblk.TTF", "Arial Black");
                    RegisterFont(args[0], "comic.TTF", "Comic Sans MS");
                    RegisterFont(args[0], "cour.TTF", "Courier New Regular");
                    RegisterFont(args[0], "courbd.TTF", "Courier New Bold");
                    RegisterFont(args[0], "courbi.TTF", "Courier New Bold Italic");
                    RegisterFont(args[0], "couri.TTF", "Courier New Italic");
                    RegisterFont(args[0], "coure.fon", "Courier Regular");
                    RegisterFont(args[0], "georgia.ttf", "Georgia");
                    RegisterFont(args[0], "HATTEN.TTF", "Haettenschweiler (TrueType)");
                    RegisterFont(args[0], "impact.TTF", "Impact");
                    RegisterFont(args[0], "linc.fon", "LINC Default");
                    RegisterFont(args[0], "LFAX.TTF", "Lucida Fax Regular (TrueType)");
                    RegisterFont(args[0], "LFAXDI.TTF", "Lucida Fax Demibold Italic (TrueType)");
                    RegisterFont(args[0], "LFAXI.TTF", "Lucida Fax Italic (TrueType)");
                    RegisterFont(args[0], "malgun.ttf", "@Malgun Gothic");
                    RegisterFont(args[0], "mangal.ttf", "Mangal (TrueType)");
                    RegisterFont(args[0], "mangalb.ttf", "Mangal Bold (TrueType)");
                    RegisterFont(args[0], "micross.ttf", "Microsoft Sans Serif");
                    RegisterFont(args[0], "msgothic.ttc", "MS Gothic & MS UI Gothic & MS PGothic (TrueType)");
                    RegisterFont(args[0], "MS Mincho.ttf", "MS Mincho (TrueType)");
                    RegisterFont(args[0], "serife.fon", "MS Serif");
                    RegisterFont(args[0], "sserife.fon", "MS Sans Serif");
                    RegisterFont(args[0], "smalle.fon", "Small Fonts");
                    RegisterFont(args[0], "tahoma.ttf", "Tahoma");
                    RegisterFont(args[0], "times.TTF", "Times New Roman Regular");
                    RegisterFont(args[0], "timesbd.TTF", "Times New Roman Bold");
                    RegisterFont(args[0], "timesbi.TTF", "Times New Roman Bold Italic");
                    RegisterFont(args[0], "timesi.TTF", "Times New Roman Italic");
                    RegisterFont(args[0], "Tt7217a.ttf", "LincDefault New (TrueType)");
                    RegisterFont(args[0], "Tt7218a.ttf", "LincDefault New Bold (TrueType)");
                    RegisterFont(args[0], "verdana.TTF", "Verdana Regular");
                    RegisterFont(args[0], "verdanab.TTF", "Verdana Bold");
                    RegisterFont(args[0], "verdanai.TTF", "Verdana Italic");
                    RegisterFont(args[0], "verdanaz.TTF", "Verdana Bold Italic");
                    RegisterFont(args[0], "vgafix.fon", "Fixedsys");
                }
                else
                {
                    Console.WriteLine("Invalid path or arguments.");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
            }

            Console.WriteLine("Done.");
        }

        private static void RegisterFont(string sourceFontPath, string fontFileName, string fontName)
        {
            string systemFontsFolder = System.Environment.GetFolderPath(System.Environment.SpecialFolder.Fonts);
            string fontDestination = Path.Combine(systemFontsFolder, fontFileName);
            string sourceFontFullPath = Path.Combine(sourceFontPath, fontFileName);

            if (!File.Exists(fontDestination))
            {
                System.IO.File.Copy(sourceFontFullPath, fontDestination);

                AddFontResource(fontDestination);
                Registry.SetValue(@"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts", fontName, fontFileName, RegistryValueKind.String);
            }
            else
            {
                Console.WriteLine("File " + sourceFontFullPath + " alreay exists.");
            }
        }
    }
}
"@

# Add the C# type to the PowerShell session.
Add-Type -TypeDefinition $csharpCode
$arguments=@("$font_dir")
[InstallFonts.Program]::Main($arguments)