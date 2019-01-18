<?php
error_reporting(E_ALL);
ini_set('log_errors', 'on');
ini_set('display_errors', 0);
$currentPath = __DIR__.DIRECTORY_SEPARATOR;
ini_set('error_log', $currentPath.'php_errors.log');
if (!isset($_REQUEST)) { 
	return; 
}

/* Настройки Chat2VK */

define('DEBUG', false); 				// true/false : включить/выключить режим отладки
define('CONSOLE', true); 				// true/false : включить/выключить поддержку sm_rcon. Пример использования : !1 sm_rcon bot_kick
define('ALL', true); 					// true/false : включить/выключить команду !all для беседы вк
$ids = array("1","2","3");		// Укажите нужные VK ID в цифрах : 142805811, а не xtance.
					// Осторожно : пользователь сможет исполнять любые ркон команды!

$conf = ''; 	// Строка для подтверждения адреса сервера из настроек Callback API
$token = '';	// Ключ доступа сообщества (токен)
$servers = [
	'1' => [			// Команда для отправки на первый сервер (может быть даже словом, главное без пробелов)
					// В беседе обязательно вводить с воскл. знаком!!
		'ip' => '', // Ип сервера
		'port' => '', // Порт сервера
		'pass' => '', // Ркон пароль сервера
	],
];


// Тоже настройки, но менять тут нечего :
$chat = '1';
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
        echo $conf;
        break;
    case 'message_new':
		echo 'ok';
		$convcheck = $data->object->id;
		if ('0' != $convcheck) {
			// Чтобы челик не мог написать боту в лс
			return;
		}
		$message = $data->object->text;
		
		$result = preg_match("#^\!(\S*)\s?(.+)?$#", $message, $matches);
		debugMessage('result', $result);
		debugMessage('matches', $matches);
		// Альтернативный метод тестирования с выводом прямо в беседу
		// file_get_contents("https://api.vk.com/method/messages.send?chat_id=1&message={$matches}&v=5.87&access_token={$token}");
		if ($result === false || count($matches) < 2) {
			return;
		}
		$isall = 'all';
		if (ALL && ($matches[1] === $isall))
		{
			include_once("rcon.class.php");
			$userId = $data->object->from_id;
			$userInfo = json_decode(file_get_contents("https://api.vk.com/method/users.get?user_ids={$userId}&v=5.87&access_token={$token}"));
		
			debugMessage('userInfo', $userInfo);
			if (!$userInfo) {
				return;
			}
			$user_name = $userInfo->response[0]->first_name;
			$last_name = $userInfo->response[0]->last_name;
			
			foreach ($servers as $key => $value)
			{
				$serverData = $servers[$key];
				$r = new rcon($serverData['ip'],$serverData['port'],$serverData['pass']);
				$r->Auth();
				if(count($matches) == 2) {
					$r->sendCommand("sm_send status&");
				}
				else {
					$message = $matches[2];
					$r->sendCommand("sm_send $user_name $last_name&$message");
				}
			}
			return;
		}
		if (!array_key_exists($matches[1], $servers)) {
			return;
		}
		
		// Авторизация через rcon
		include_once("rcon.class.php");
		$serverData = $servers[$matches[1]];
		$r = new rcon($serverData['ip'],$serverData['port'],$serverData['pass']);
		$r->Auth();
		
		// На случай если игрок захотел проверить онлайн сервера и карту
		if(count($matches) == 2) {
			$r->sendCommand("sm_send status&");
			return;
		}
		
		//	Получаем ID отправителя
		$userId = $data->object->from_id;
		
		// Ркон из ВК
		$rcon = 'sm_rcon';
		if (CONSOLE && (strncmp($matches[2], $rcon, strlen($rcon)) === 0))
		{
			if (in_array($userId, $ids))
			{
				$r->sendCommand("${matches[2]}");
			}
			else
			{
				file_get_contents("https://api.vk.com/method/messages.send?chat_id={$chat}&message=@id{$userId}%20(Вы)%20не%20можете%20использовать%20RCON.&v=5.87&access_token={$token}");
			}
			return;
		}
		
		$userInfo = json_decode(file_get_contents("https://api.vk.com/method/users.get?user_ids={$userId}&v=5.87&access_token={$token}"));
		
		debugMessage('userInfo', $userInfo);
		if (!$userInfo) {
			return;
		}
		$user_name = $userInfo->response[0]->first_name;
		$last_name = $userInfo->response[0]->last_name;
		
		$message = $matches[2];
		$r->sendCommand("sm_send $user_name $last_name&$message");
		// $logMsg = date('Y-m-d H:i:s').' '.$user_name.' '.$last_name.': '.$message;
		// file_put_contents($logPath, $logMsg.PHP_EOL, FILE_APPEND);
		break;
}
