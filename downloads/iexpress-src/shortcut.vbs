dest = WScript.Arguments(0)
Set shell = CreateObject("WScript.Shell")
Set link = shell.CreateShortcut(shell.SpecialFolders("Desktop") & "\TEZVPN.lnk")
link.TargetPath = dest & "\TEZVPN.exe"
link.WorkingDirectory = dest
link.Save
