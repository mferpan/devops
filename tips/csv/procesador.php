<?php
session_start();
$selectDestino=$_GET["select"];
$opcionSeleccionada=$_GET["opcion"];

if ($selectDestino == "select2") {
   $_SESSION["select1"] = $opcionSeleccionada;
}

$a_data = array();
if (($handle = fopen("combos.csv", "r")) !== FALSE) {
   echo "<select name='".$selectDestino."' id='".$selectDestino."' onChange='cargaContenido(this.id)'>";
   echo "<option value='0'>Select an option...</option>";

   while (($data = fgetcsv($handle, 1000, ";")) !== FALSE) {
      if ($selectDestino=="select3"){
         if ($opcionSeleccionada==$data[2] && $_SESSION['select1']==$data[0] ){
            $a_data[]=$data[1];
         }
      } else {
         if ($opcionSeleccionada==$data[0]){
            $a_data[]=$data[2];
         }
      }
   }
   fclose($handle);

   $_data=array_unique($a_data);
   sort($_data, SORT_NATURAL | SORT_FLAG_CASE);
   foreach($_data as $key => $value) {
      echo "<option value=\"".$value."\">".$value."</option>\n";
   }
   echo "</select>";
}
?>
