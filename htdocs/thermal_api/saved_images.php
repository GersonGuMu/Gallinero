<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");

if (!isset($_POST['image'])) {
    echo json_encode(["status"=>"error","message"=>"No image"]);
    exit;
}

$img = $_POST['image'];
$img = str_replace('data:image/jpeg;base64,', '', $img);
$img = base64_decode($img);

// carpeta
$folder = "captures/";
if (!file_exists($folder)) mkdir($folder);

$filename = "cap_" . time() . "_" . rand(1000,9999) . ".jpg";
file_put_contents($folder . $filename, $img);

echo json_encode([
    "status"=>"success",
    "file"=>$filename
]);
