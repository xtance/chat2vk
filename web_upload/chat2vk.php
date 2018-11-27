<?php

// Код отсюда : https://habr.com/post/329150/ и https://fremnet.net/article/199/source-rcon-class
// Адаптировано под плагин Chat2VK : https://hlmod.ru/threads/chat-2-vkontakte.46248/ , XTANCE : https://steamcommunity.com/id/xtance
// Пожалуйста, заполните настройки :

$confirmationToken = 'подтверждение'; 	// Строка для подтверждения адреса сервера из настроек Callback API
$token = 'токенчик';	// Ключ доступа сообщества (токен)

$cmd1	= '!1'; 	// Команда для отправки на первый сервер
			// Внимание :
			// !1 может быть любым текстом, восклицательный знак необязателен.

$ip1	= 'айпишник'; 	// Айпи первого сервера
$port1	= 'порт'; 	// Порт первого сервера
$pass1	= 'пароль'; 	// Ркон первого сервера

// ВАЖНО : не забудь закрыть возможность добавления бота в беседы
// ВАЖНО : в списке участников беседы дайте боту "доступ ко всей переписке"

// Для тех, у кого больше одного сервера :

$cmd2	= '!2';
$ip2	= 'айпишник';
$port2	= 'порт';
$pass2	= 'пароль';
$cmd3	= '!3';
$ip3	= 'айпишник';
$port3	= 'порт';
$pass3	= 'пароль';
$cmd4	= '!4';
$ip4	= 'айпишник';
$port4	= 'порт';
$pass4	= 'пароль';
$cmd5	= '!5';
$ip5	= 'айпишник';
$port5	= 'порт';
$pass5	= 'пароль';


$data = json_decode(file_get_contents('php://input'));
if (!isset($_REQUEST)) {
	return;
}

switch ($data->type) {
	
    case 'confirmation':
        echo $confirmationToken;
        break;

    case 'message_new':
		echo('ok');
		$convcheck = $data->object->id;
		if ('0' == $convcheck) // Чтобы челик не мог написать боту в лс
		{
			include_once("rcon.class.php");
			$message = $data->object->text;
			
			// Кривой код. Написано плохо.
			// Кто-нибудь, помогите!
			if(strpos($message, $cmd1) === 0) {
				$r = new rcon($ip1,$port1,$pass1);
			}
			else if(strpos($message, $cmd2) === 0) {
				$r = new rcon($ip2,$port2,$pass2);
			}
			else if(strpos($message, $cmd3) === 0) {
				$r = new rcon($ip3,$port3,$pass3);
			}
			else if(strpos($message, $cmd4) === 0) {
				$r = new rcon($ip4,$port4,$pass4);
			}
			else if(strpos($message, $cmd5) === 0) {
				$r = new rcon($ip5,$port5,$pass5);
			}
			else { break; }
			
			$r->Auth();
			$userId = $data->object->from_id;
			$userInfo = json_decode(file_get_contents("https://api.vk.com/method/users.get?user_ids={$userId}&v=5.87&access_token={$token}"));
			$user_name = $userInfo->response[0]->first_name;
			$last_name = $userInfo->response[0]->last_name;
			$message = substr($message, strlen($cmd1));
			$r->sendCommand("sm_send $user_name $last_name&$message");
		}
		break;
}
?>
