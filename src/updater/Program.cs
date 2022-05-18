using System;
using System.Runtime.InteropServices;

namespace PnpUpdater
{
    class DriverInstaller
    {
        public static bool UpdatePL2303(string hardwareId, string infPath)
        {            
            // INSTALL FLAG: FORCE = 0x00000001, NONINTERACTIVE = 0x00000004
            uint flags = 5;

            return UpdateDriverForPlugAndPlayDevices(IntPtr.Zero, hardwareId, infPath, flags, IntPtr.Zero);
        }

        [DllImport("newdev.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool UpdateDriverForPlugAndPlayDevices(
            IntPtr hwndParent,
            [In, MarshalAs(UnmanagedType.LPTStr)] string HardwareId,
            [In, MarshalAs(UnmanagedType.LPTStr)] string FullInfPath,
            uint InstallFlags,
            IntPtr bRebootRequired
        );

    }
    class Program
    {
        static int Main(string[] args)
        {            
            int exitCode = 0;
            string hardwareId = args.Length > 0 ? args[0].Trim() : "";
            string infPath = args.Length > 1 ? args[1].Trim() : "";

            if (!DriverInstaller.UpdatePL2303(hardwareId, infPath))
            {
                int error = Marshal.GetLastWin32Error(); 
                exitCode = error != 0 ? error : -1;  
            }

            return exitCode;
        }
    }
}
