$insert_count = 1000
$words = @('bobby','mikey','billy','suzie','kenny','narav','navneet','rachel','jose','juan')
$conn = New-Object System.Data.SqlClient.SqlConnection
$conn.ConnectionString = “Server='SBX-MISC-DBS02';Database='sandbox_ae';Column Encryption Setting=enabled;Integrated Security=True;”
$conn.Open()

for ($i = 0; $i -le $insert_count; $i++) {
    $val = Get-Random -Maximum 10
    $word_to_insert = $words[$val]
    $sqlcmd = New-Object System.Data.SqlClient.SqlCommand
    $sqlcmd.Connection = $conn
    $sqlcmd.CommandText = “insert into dbo.dog_poop ([stuff]) VALUES (@value)”
    $sqlcmd.Parameters.Add((New-Object Data.SqlClient.SqlParameter(“@value”,[Data.SQLDBType]::VarChar, 4000)))
    $sqlcmd.Parameters[0].Value = $word_to_insert
    $sqlcmd.ExecuteNonQuery();
}
$conn.Close()

