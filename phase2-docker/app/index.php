<?php
// Simulated Laravel Application Entrypoint
header('Content-Type: application/json');

$response = [
    'status' => 'success',
    'message' => 'Welcome to the Production-Grade Laravel Containerized API!',
    'environment' => getenv('APP_ENV') ?: 'production',
    'database_connected' => false,
    'redis_connected' => false
];

// Check Database Connection if configured
$db_host = getenv('DB_HOST');
$db_name = getenv('DB_DATABASE');
$db_user = getenv('DB_USERNAME');
$db_pass = getenv('DB_PASSWORD');

if ($db_host && $db_name) {
    try {
        $dsn = "mysql:host=$db_host;dbname=$db_name;charset=utf8mb4";
        $pdo = new PDO($dsn, $db_user, $db_pass, [
            PDO::ATTR_TIMEOUT => 2,
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
        ]);
        $response['database_connected'] = true;
    } catch (PDOException $e) {
        $response['database_error'] = $e->getMessage();
    }
}

// Check Redis Connection if configured
$redis_host = getenv('REDIS_HOST');
if ($redis_host) {
    try {
        $redis = new Redis();
        $connected = $redis->connect($redis_host, 6379, 1.5);
        if ($connected) {
            $response['redis_connected'] = true;
        }
    } catch (Exception $e) {
        $response['redis_error'] = $e->getMessage();
    }
}

echo json_encode($response, JSON_PRETTY_PRINT);
