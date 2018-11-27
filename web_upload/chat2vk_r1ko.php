<?php
error_reporting(E_ALL);
ini_set('log_errors', 'on');
ini_set('display_errors', 0);
$currentPath = __DIR__.DIRECTORY_SEPARATOR;
ini_set('error_log', $currentPath.'php_errors.log');
if (!isset($_REQUEST)) { 
	return; 
}
define('DEBUG', false); // true Для включения режима отладки
$confirmationToken = ''; 	// Строка для подтверждения адреса сервера из настроек Callback API
$token = '';	// Ключ доступа сообщества (токен)
$servers = [
	'1' => [			// Команда для отправки на первый сервер (может быть даже словом, главное без пробелов)
		'ip' => '', // Ип сервера
		'port' => '', // Порт сервера
		'pass' => '', // Ркон пароль сервера
	],
];
$date = date('Y-m-d');
$logPath = $currentPath.'messages_'.$date.'.log';
$debugLogPath = $currentPath.'debug_'.$date.'.log';
function debugMessage($title, $data) {
	global $debugLogPath;
	if (DEBUG) {
		file_put_contents($debugLogPath, $title.':'.print_r($data, true).PHP_EOL, FILE_APPEND);
	}
}
$data = json_decode(file_get_contents('php://input'));
debugMessage('REQUEST', $data);
switch ($data->type) {
    case 'confirmation':
        echo $confirmationToken;
        break;
    case 'message_new':
		echo 'ok';
		$convcheck = $data->object->id;
		if ('0' != $convcheck) {	// Чтобы челик не мог написать боту в лс
			return;
		}
		$message = $data->object->text;
		$result = preg_match("#^\!(\S*)\s(.*)$#", $message, $matches);
		debugMessage('result', $result);
		debugMessage('matches', $matches);
		if ($result === false || count($matches) != 3) {
			return;
		}
		if (!array_key_exists($matches[1], $servers)) {
			return;
		}
		$userId = $data->object->from_id;
		$userInfo = json_decode(file_get_contents("https://api.vk.com/method/users.get?user_ids={$userId}&v=5.87&access_token={$token}"));
		debugMessage('userInfo', $userInfo);
		if (!$userInfo) {
			return;
		}
		$user_name = $userInfo->response[0]->first_name;
		$last_name = $userInfo->response[0]->last_name;
		include_once("rcon.class.php");
		$serverData = $servers[$matches[1]];
		$r = new rcon($serverData['ip'],$serverData['port'],$serverData['pass']);
		$r->Auth();
		$message = $matches[2];
		$r->sendCommand("sm_send $user_name $last_name&$message");
		$logMsg = date('Y-m-d H:i:s').' '.$user_name.' '.$last_name.': '.$message;
		file_put_contents($logPath, $logMsg.PHP_EOL, FILE_APPEND);
		break;
}
