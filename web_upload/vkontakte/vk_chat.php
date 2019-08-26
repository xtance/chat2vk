<?php
use Medoo\Medoo;
require_once 'vk_class.php';

header('Content-Type: text/html; charset=utf-8');
if (!isset($_REQUEST)) die;
$data = json_decode(file_get_contents('php://input'));
if (empty($data)) die;
if (strcmp($data->secret, VK_SECRET) !== 0) die;

switch ($data->type) {
    case 'confirmation':
        echo VK_CONFIRMATION;
		die;
    case 'message_new':
		echo 'ok';
		
		$message = $data->object->text;
		$result = preg_match("#^\!(\S*)\s?(.+)?$#", $message, $matches);
		if ($result === false || count($matches) < 2) die;
		
		$vk = new VKontakte();
		$userid = $data->object->from_id;
		$peerid = $data->object->peer_id;
		
		if (array_key_exists($matches[1], SERVERS)){
			if(count($matches) == 2) $vk->get($peerid, $matches[1]);
			else if (strpos($matches[2], 'sm_rcon') === 0) {
				if (in_array($userid, VK_ADMINS)) $vk->execute($peerid, $matches[1], $matches[2], true);
				else $vk->send_vk($peerid, '@id' . $userid . ' (Вы) не можете использовать RCON');
			}
			else if ($matches[2] === 'steam') $vk->get($peerid, $matches[1], true);
			else $vk->send($peerid, $userid, $matches[1], $matches[2]);
		}
		else if ($matches[1] === 'all' || $matches[1] === 'все'){
			if(count($matches) == 2) $vk->get_all($peerid);
			else if (strpos($matches[2], 'sm_rcon') === 0){
				if (in_array($userid, VK_ADMINS)) $vk->execute_all($peerid, $matches[2], true);
				else $vk->send_vk($peerid, '@id' . $userid . ' (Вы) не можете использовать RCON');
			}
			else $vk->send_all($peerid, $userid, $matches[2]);
		}
		
		
	/* 	Примеры кастомных команд, которые можно сюда дописать... $peerid - это либо беседа, либо пользователь (если в лс). $userid - тот, кто вызвал бота
			
		else if ($matches[1] === 'hello'){
			$vk->send_vk($peerid, 'Привет, @id' . $userid . ' (пользователь)!');
		}
		
		else if ($matches[1] === 'rules'){
			$vk->send_vk($peerid, 'Правила беседы: %0A Правило #1 %0A Правило #2');
		}
		
	*/
		
		else if (VK_STEAMBOT){
			if ($matches[1] === 'steam'){
				if(count($matches) == 2){
					$fwd = $vk->get_forwarded_id($data);
					if ($fwd > 0) {
						$results = $vk->get_steam($fwd);
						if (empty($results)) $vk->send_vk($peerid, '@id' . $fwd . ' (Данного игрока) ещё нет в базе. Предложите ему зарегистрироваться (!reg)');
						else {
							$str = '';
							foreach ($results as $value){
								$str .= 'Steam: https://steamcommunity.com/profiles/' . $value['steam_id'] . '%0AДата регистрации: ' . date("d.m.Y, H:i", $value['steam_date']) . '%0A';
							}
							$str .= '%0A%0AVK: https://vk.com/id' . $results[0]['vk_id'];
							$vk->send_vk($peerid, $str);
						}
					}
					else $vk->send_vk($peerid, 'Чтобы узнать Steam человека, введите ссылку на его VK:%0A!steam vk.com/id142805811%0AИли перешлите мне его сообщение с этой же командой.%0A%0AЧтобы привязать свой Steam, напишите мне в личку !reg');
				}
				else{
					$results = $vk->get_steam($matches[2]);
					if (empty($results)) $vk->send_vk($peerid, 'Данного игрока ещё нет в базе. Предложите ему зарегистрироваться (!reg)');
					else {
						$str = '';
						foreach ($results as $value){
							$str .= 'Steam: https://steamcommunity.com/profiles/' . $value['steam_id'] . '%0AДата регистрации: ' . date("d.m.Y, H:i", $value['steam_date'])  . '%0A';
						}
						$str .= '%0A%0AVK: https://vk.com/id' . $results[0]['vk_id'];
						$vk->send_vk($peerid, $str);
					}
				}
			}
			else if ($matches[1] === 'vk'){
				if(count($matches) == 2) $vk->send_vk($peerid, 'Чтобы узнать VK человека, введите ссылку на его Steam:%0A!vk steamcommunity.com/id/xtance');
				else{
					$results = $vk->get_vk($matches[2]);
					if (empty($results)) $vk->send_vk($peerid, 'Данного игрока ещё нет в базе. Предложите ему зарегистрироваться (!reg)');
					else {
						$str = '';
						$vk->put('vk results',$results);
						foreach ($results as $value){
							$str .= 'VK: https://vk.com/id' . $value['vk_id']  . '%0A';
						}
						$str .= '%0A%0ASteam: https://steamcommunity.com/profiles/' .  $results[0]['steam_id'];
						$vk->send_vk($peerid, $str);
					}
				}
			}
			else if ($matches[1] === 'reg'){
					if($vk->is_personal($peerid)){
					
					require '../scripts/Medoo/Medoo.php';
					$db = new Medoo(MEDOO_CFG);
					$db->create('helper',[
						'id' => ['INT','NOT NULL'],
						'code' => ['VARCHAR(20)','NOT NULL'],
					]);
					$db->create('vk',[
						'vk_id' => ['INT','NOT NULL'],
						'steam_id' => ['VARCHAR(60)','NOT NULL'],
						'steam_date' => ['INT'],
					]);
					
					$arr = $db->select('helper', 'code', ['id' => $userid]);
					$vk->put($peerid, $arr);
					if(empty($arr)){
						$code = substr(str_shuffle('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'),1,15);
						$db->insert('helper',[
							'id' => $userid,
							'code' => $code,
						]);
						$link = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http") . "://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['REQUEST_URI']) . '/vk_steam.php?reg=' . $code; 
						$vk->send_vk($peerid, 'Перейдите по ссылке, чтобы завершить привязку аккаунта: ' . $link . '%0A %0AАвторизация происходит на стороне Steam, бот не получает логин/пароль.');
					} else {
						$link = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http") . "://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['REQUEST_URI']) . '/vk_steam.php?reg=' . $arr[0]; 
						$vk->send_vk($peerid, 'Перейдите по ссылке, чтобы завершить привязку аккаунта: ' . $link . '%0A %0AАвторизация происходит на стороне Steam, бот не получает логин/пароль.');
					}
				} else $vk->send_vk($peerid, 'Команда !reg доступна только в личных сообщениях. Напишите мне!');
			}
			else if ($matches[1] === 'tie'){
				if (in_array($userid, VK_ADMINS)){
					$fwd = $vk->get_forwarded_id($data);
					if ($fwd > 0) {
						$s = $vk->steam64($matches[2]);
						if ($s > 0) $vk->tie($peerid, $s, $fwd);
						else $vk->send_vk($peerid, 'Не удалось сделать Steam64, попробуйте другой формат SteamID');
					} else $vk->send_vk($peerid, 'Необходимо переслать мне сообщение от нужного профиля VK + ссылку на Steam.');
				} else $vk->send_vk($peerid, 'Это админская команда!');
			}
			else if ($matches[1] === 'untie'){
				if (in_array($userid, VK_ADMINS)){
					$fwd = $vk->get_forwarded_id($data);
					if ($fwd > 0) {
						$vk->untie($peerid, $fwd);
					} else $vk->send_vk($peerid, 'Чтобы отвязать человека от бота, перешлите его сообщение с командой !untie');
				} else $vk->send_vk($peerid, 'Это админская команда!');
			}
			else die; //видимо, не в этот раз..
		} else die; //сегодня нам определённо не везёт.
}
die; //с кем не бывает!