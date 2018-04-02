# wsadmin

Module Name: wsadmin
=========

Модули по работе с IBM WAS wsadmin


Данные модули предназначены для упрощения работы с wsadmin. В модулях реализован функционал автоматического скрытия паролей в случайные переменные окружения т.о. при любом исходе выполнения пароль не будет отображаться. 
Так же добавлены такие возможности как: 

- перенаправленные потоков вывода в файл
- запуск скриптов на выполнение с (параметрами и без) 
- передача команд
- активация записи traice файла 
- принятие SSL сертификатов

Requirements:
---------

-  Ansible >= ansible 2.4.0.0

**[windows]**

-  PowerShell v3.0 и выше
-  служба WinRM должна быть запущенна 

## Аналогичные возможности из wsadmin ##
`

    wsadmin
        [ -c  "команда" - это команда для передачи в обработчик сценариев]
        [ -f  "файл-сценария" - это команда для передачи в обработчик сценариев]
        [ -javaoption "опция-java" - это стандартная или нестандартная опция для передачи в программу java;]
        [ -lang  "язык" - это язык для обработки сценариев. Поддерживаемые значения - "jacl" и "jython".]
        [ -conntype - задает тип применяемого соединения значение по умолчанию - "SOAP"
			Поддерживаемые значения:
                SOAP
                RMI
                        [-host "хост" - хост, используемый для соединений SOAP или RMI; значение по умолчанию - localhost;]
                        [-port  "порт" - порт, используемый для соединений SOAP или RMI;]
                        [-user "ид-пользователя" - ИД пользователя, необходимый при работе сервера в безопасном режиме;]
                        [-password "пароль" - это пароль, необходимый при работе сервера в безопасном режиме;]
        ]
        [ -tracefile "файл-трассировки" - расположение файла протокола, к которому направляется трассировка wsadmin]
        [ "параметры сценария" - прочая информация в командной строке.  Эти параметры передаются в сценарий в переменной argv; количество параметров доступно в переменной argc. ]
`

## Подключение к проекту
----------
Для возможности использования данных модулей в своем проекте/роле Вам необходимо в корневой директории проекта создать директорию:  

> library

затем необходимо в нее скопировать файлы:
> wsadmin.py - для Nix сред
> 
> win_wsadmin.py - для Win сред

После чего в проете станут доступны указанные модули.

Role Variables
---------
## Обязательные параметры: ##
  - wasdir - путь до wsadmin.(bat/sh)
    > [для Windows] wasdir: D:/IBM/WebSphere/AppServer/bin
    > [для Nix] wasdir: /opt/IBM/WebSphere/AppServer/bin
>    wasdir: D:/IBM/WebSphere/AppServer/bin


## Опциональные параметры: ##
  - **`washost:`** - FQDN or IP хост для подключения (***-host***)
    > Зависит от: **`wasdir`** Если используется корневой (не из профайла, то необходим)
  - **`wasport:`** - SOAP port (***-port***) 
    > Зависит от: **`wasdir`** Если используется корневой (не из профайла, то необходим)
  - **`conntype:`** - SOAP ... (***-conntype***)
  - **`lang:`** - Jython/Jacl (***-lang***)
  - **`was_params:`** - Строка параметров запуска WAS (***-javaoption***)(пример -javaoption -Xms256m -javaoption -Xmx1024m) 
  - **`tracefile:`** - Путь "куда сохранить" трайс файл (***-tracefile***)
  - **`username:`** - Имя пользователя если используется (***-user***)
    > Зависит от: есть ли аторизация или нет
  - **`password:`** - Пароль если используется (***-password***)
    > Зависит от: есть ли аторизация или нет
  - **`script:`** - Полный путь до скрипта (***-f  "файл-сценария"***) 
  - **`script_params:`** - Параметры запуска скрипта		(***параметры сценария***)
  - **`was_command:`** - Выполнение произвольной команды  (***-c ***)
  - **`accept_cert:`** - Разрешение на принятие сертификата WAS данный шаг рекомендовано выполнять как отдельный с указанием was_command: 'sys.exit'
    > Зависит от: **`washost:`** и **`wasport:`**


Example ansible-playbook:
---------
    ---
    - hosts: **some_host**
      tasks:
        - name: Apply ssl cert
          wsadmin:
          args:
            accept_cert: true
            wasdir: D:/IBM/WebSphere/AppServer/bin
            wasport: 8880
            washost: 127.0.0.1
            was_command: 'sys.exit'
          register: cert_true
          ignore_errors: True
        - name: Deploy app
          win_wsadmin:
          args:
            wasdir: D:/IBM/WebSphere/AppServer/bin
            washost: 127.0.0.1
            wasport: 8880
            conntype: SOAP
            lang: jython
            was_params: -javaoption -Xms256m -javaoption -Xmx1024m
            tracefile: D:/trace.log
            username: was_username
            password: was_password
            script: D:/was_script.py
            accept_cert: false
          register: wsadmin_win
    ...

Example Пример 1
----------
*Запустить wsadmin с указанием java параметров на хосте ОС Windows и выполнить сценарий was_script.py результаты работы перенаправить 
в лог-файлы stdout.log и stderr.log*

    - win_wsadmin:
      args:
        wasdir: D:/IBM/WebSphere/AppServer/bin
        washost: 127.0.0.1
        wasport: 8880
        conntype: SOAP
        lang: jython
        was_params: -javaoption -Xms256m -javaoption -Xmx1024m
        tracefile: D:/trace.log
        username: was_username
        password: was_password
        script: D:/was_script.py
        script_params: "1> D:/stdout.log 2> D:/stderr.log"
        was_command: ""
        accept_cert: false
      register: wsadmin_win

Example Пример 2
----------
*Запустить wsadmin на хосте ОС Nix и принять SSL сертификат*

    - wsadmin:
      args:
        accept_cert: true
        wasdir: D:/IBM/WebSphere/AppServer/bin
        wasport: 8880
        washost: 127.0.0.1
        was_command: 'sys.exit'
      register: cert_true
      ignore_errors: True

Example Пример 3
----------
*Запустить wsadmin на хосте ОС Windows из папки директории профайла и выполнить сценарий was_script.py результаты работы перенаправить 
в лог-файлы stdout.log и stderr.log
записать trace в файл trace.log*

    - win_wsadmin:
      args:
        wasdir: D:/IBM/WebSphere/AppServer/profiles/AppSrv01/bin
        tracefile: D:/trace.log
        username: was_username
        password: was_password
        script: D:/was_script.py
        script_params: "1> D:/stdout.log 2> D:/stderr.log"
      register: wsadmin_win


Author Information
---------
Румянцев Юрий Николаевич
[rumyanec@gmail.com](mailto:"rumyanec@gmail.com")

rev. 4/2/2018 11:09:13 AM 
