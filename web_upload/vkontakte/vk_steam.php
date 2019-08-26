<?php
	use Medoo\Medoo;
	require 'vk_class.php';
	require '../scripts/Medoo/Medoo.php';
	require 'SteamAuth.php';
?>
<!DOCTYPE html>
<html lang="en">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Steam + VK</title>
<style>
	body{
		margin:1em auto;
		max-width:40em;
		padding:0.62em;
		font: 1.2em/1.62 -apple-system, BlinkMacSystemFont, /* MacOS and iOS */
	   'avenir next', avenir, /* MacOS and iOS */
	   'Segoe UI', /* Windows */
	   'lucida grande', /* Older MacOS */
	   'helvetica neue', helvetica, /* Older MacOS */
	   'Fira Sans', /* Firefox OS */
	   roboto, noto, /* Google stuff */
	   'Droid Sans', /* Old Google stuff */
	   cantarell, oxygen, ubuntu, /* Linux stuff */
	   'franklin gothic medium', 'century gothic', /* Windows stuff */
	   'Liberation Sans', /* Linux */
	   sans-serif; /* Everything else */;
	}
	h1,h2,h3 {
		line-height:1.2;
	}
	@media print{
		body{
			max-width:none
		}
	}
</style>
<article>
	<?php
		$db = new Medoo(MEDOO_CFG);
		if(isset($_GET['reg'])){
			$steam = new Vikas5914\SteamAuth(STEAM_API);
			$arr = $db->select('helper', 'id', ['code' => $_GET['reg']]);
			if (empty($arr)){
				echo '<h1>Ошибка!</h1>';
				echo '<p>Данная ссылка больше не работает.<hr>';
			} else{
				if ($steam->loggedIn()){
					if ($db->has('vk',['steam_id' => $steam->steamid])){
						echo '<h1>Ошибка!</h1>';
						echo '<p>Этот аккаунт Steam уже привязан к <a href="https://vk.com/id' . $arr[0] . '">ВКонтакте</a>!</br>';
						echo '</br><a href=' . $steam->logout() . '>[Выйти из Steam]</a></br><hr>';
					} else {
						$db->delete('helper', [
							'OR' => [
								'id' => $arr[0],
								'code' => $_GET['reg'],
							]
						]);
						$db->insert('vk',[
							'vk_id' => $arr[0],
							'steam_id' => $steam->steamid,
							'steam_date' => $steam->timecreated,
						]);
						
						echo '<h1>Готово!</h1>';
						echo '<p>Спасибо за регистрацию.</p></br><hr>';
						
						$vk = new VKontakte();
						$vk->send_vk($arr[0], 'Регистрация успешна. Команды для вас:%0A!vk steamcommunity.com/profiles/' . $steam->steamid . '%0A!steam vk.com/id' . $arr[0]);
					}
				} else {
					echo '<h1>Внимание!</h1>';
					echo '<p>Вы собираетесь привязать Steam к <a href="https://vk.com/id' . $arr[0] . '"  target="_blank" rel="noopener noreferrer">своей странице ВКонтакте.</a></br> Необходимо войти в аккаунт.</p>';
					echo '<a href=' . $steam->loginUrl() . '>[Авторизация]</a></br><hr>';
				}
			}
		}
		
		echo '<h1>Что это?</h1>';
		echo '<p>Бот позволяет быстро найти нужного игрока и не потерять его при смене ника.</br>Команды: <b>!steam, !vk</b>';
		echo '</br>Это удастся только если игрок уже есть в нашей базе.</p>';
		echo '<p>Чтобы связать свой Steam и VK, <a href="https://' . VK_LINK . '"  target="_blank" rel="noopener noreferrer">напишите боту в личные сообщения</a> команду <b>!reg</b> и перейдите по ссылке. Админ проекта может связать ваши аккаунты вручную!</p>';
		echo '<hr><p>Зарегистрировано ' . $db->count('vk','steam') . ' уникальных пользователей.</br>';
		echo 'Используется <a href=https://github.com/vikas5914/steam-auth>SteamAuth</a>, <a href=https://medoo.in>Medoo</a> и <a href=https://github.com/xPaw/PHP-Source-Query>SourceQuery</a>, CSS от <a href=https://github.com/LeoColomb/perfectmotherfuckingwebsite>LeoColomb</a></br>';
		echo 'Работает через <a href=https://github.com/xtance/chat2vk>Chat2VK</a> 2.0 </p>';
		
		/*	разметка и код в одном файле, дадая:3 */
	?>
</article>