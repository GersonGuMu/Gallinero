<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Ruta a la carpeta de capturas en tu servidor
$directory = "./captures/"; 

$images = glob($directory . "*.{jpg,jpeg,png,gif}", GLOB_BRACE);
$fileList = array();

foreach($images as $image) {
    // Solo queremos el nombre del archivo, no la ruta completa
    $fileList[] = basename($image);
}

// Devuelve algo como: ["captura1.jpg", "captura2.jpg"]
echo json_encode($fileList);
?>