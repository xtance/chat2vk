## chat2vk
Позволяет отправлять сообщение в чат ВКонтакте прямо из сервера. 
### !vk любой текст
Плагин тестировался только для CS:GO, требует SteamWorks : http://users.alliedmods.net/~kyles/builds/SteamWorks/ или Rest in PAWN : https://forums.alliedmods.net/showthread.php?t=298024

Для компилирования нужно кинуть в /scripting/include следующие INC : [SourceComms](https://github.com/sbpp/sourcebans-pp/tree/v1.x/game/addons/sourcemod/scripting/include), [ColorVariables](https://github.com/PremyslTalich/ColorVariables/blob/master/addons/sourcemod/scripting/includes/colorvariables.inc), [Autoexecconfig](https://github.com/Impact123/AutoExecConfig/blob/development/autoexecconfig.inc), [SW](https://github.com/KyleSanderson/SteamWorks/blob/master/Pawn/includes/SteamWorks.inc) , [RIP](https://forums.alliedmods.net/showthread.php?t=298024)
 
## Как пользоваться плагином Chat2VK :
0) Кинуть chat2vk.smx в csgo/addons/sourcemod/plugins и запустить его (для генерации конфига)
1) Сделать группу VK
2) Управление сообществом -> Сообщения (вкл)
3) Сообщения -> Настройки для бота (в меню справа) -> Разрешить добавлять сообщество в беседы
4) Теперь на главной странице группы есть кнопка "Пригласить в беседу", сразу же пригласите и уберите эту возможность!!
5) Управление сообществом -> Настройки -> Работа с API -> создать токен с доступом к сообщениям
6) Токен положить в csgo/cfg/sourcemod/chat2vk.cfg

#### Если SteamWorks установлен впервые - перезагрузить сервер, если нет - только плагин.

## Чтобы можно было писать на сервер из беседы вк, положите файлы из web_upload к себе на хостинг (нужна поддержка пхп)
Все настройки в chat2vk.php, гайд по подключению бота здесь https://vk.com/dev/callback_api !


## По вопросам : [vk.com/xtance](https://vk.com/xtance "Мой вконтактик") + [t.me/xtance](https://t.me/xtance "Уютная телега") + тема на HLmod :з

Скриншоты :

![screen1](https://i.imgur.com/VNDZuwN.jpg "Screen 1")
![screen2](https://i.imgur.com/cnG0iK3.jpg "Screen 2")
![screen3](https://i.imgur.com/OE3qyg8.png "Screen 3")
