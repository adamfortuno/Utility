$f = new-object System.IO.FileStream 'X:\default_files_backup\FULL_(local)_Polonium_20150527_230656.sqb', Create, ReadWrite
$f.SetLength(18595.73MB)
$f.Close()