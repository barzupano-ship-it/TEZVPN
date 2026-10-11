using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Windows.Forms;

static class Program {
    static int Main() {
        try {
            string dest = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "TEZVPN");
            Directory.CreateDirectory(dest);
            Extract(dest);
            string app = Path.Combine(dest, "TEZVPN.exe");
            if (!File.Exists(app)) {
                MessageBox.Show("Не удалось установить TEZVPN.", "TEZVPN",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                return 1;
            }
            Process.Start(new ProcessStartInfo {
                FileName = app,
                WorkingDirectory = dest,
                UseShellExecute = true
            });
            return 0;
        } catch (Exception ex) {
            MessageBox.Show(ex.Message, "TEZVPN",
                MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }

    static void Extract(string destRoot) {
        string rootFull = Path.GetFullPath(destRoot)
            .TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
        using (var payload = Assembly.GetExecutingAssembly().GetManifestResourceStream("TezPayload")) {
            if (payload == null) throw new InvalidDataException("Повреждённый файл TEZVPN.");
            using (var zip = new ZipArchive(payload, ZipArchiveMode.Read)) {
                foreach (ZipArchiveEntry entry in zip.Entries) {
                    string name = entry.FullName.Replace('\\', '/');
                    if (name.StartsWith("TEZVPN/", StringComparison.OrdinalIgnoreCase))
                        name = name.Substring("TEZVPN/".Length);
                    if (name.Length == 0 || name.EndsWith("/", StringComparison.Ordinal)) continue;
                    if (name.IndexOf("..", StringComparison.Ordinal) >= 0) continue;
                    string target = Path.GetFullPath(Path.Combine(destRoot, name.Replace('/', Path.DirectorySeparatorChar)));
                    if (!target.StartsWith(rootFull, StringComparison.OrdinalIgnoreCase)) continue;
                    string dir = Path.GetDirectoryName(target);
                    if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);
                    try {
                        entry.ExtractToFile(target, true);
                    } catch (IOException) {
                        if (!File.Exists(target)) throw;
                    }
                }
            }
        }
    }
}
