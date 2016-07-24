<?php

session_start();

function genSelect() {
   $a_depts = array();
   if (($handle = fopen("combos.csv", "r")) !== FALSE) {
      echo "<select name='select1' id='select1' onChange='cargaContenido(this.id)'>";
      echo "<option value='0'>Select an option...</option>";

      while (($data = fgetcsv($handle, 1000, ";")) !== FALSE) {
         $a_depts[]=$data[0];
      }
      fclose($handle);
   
      $depts=array_unique($a_depts);
      sort($depts, SORT_NATURAL | SORT_FLAG_CASE);
      foreach($depts as $key => $value) {
         echo "<option value=\"".$value."\">".$value."</option>\n";
      }
      echo "</select>";
   }
}
?>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html lang="es">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>PE</title>
<script type="text/javascript" src="combos.js"></script>
</head>

<body>
<form action="index.php" method="post">
			<div id="demo" style="width:600px;">
				<div id="demoIzq"><?php genSelect(); ?></div>
				<div id="demoMed">
					<select disabled="disabled" name="select2" id="select2">
						<option value="0">Select an option...</option>
					</select>
				</div>
				<div id="demoDer">
					<select disabled="disabled" name="select3" id="select3">
						<option value="0">Select an option...</option>
					</select>
				</div>
			</div>
			<input type="submit">
</form>
</body>
</html>
