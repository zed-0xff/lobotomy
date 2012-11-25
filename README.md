Сайт Lobotomy Team
-------------

Ставим на локалхост
======================
1. Дать мне (zed-у) свой public key, чтобы я добавил его в репу, иначе у вас не будет доступа на запись <br/> (примечание: **форкать эту репу НЕ НУЖНО**)
2. Выполнить следующее
<pre>
  git clone git@github.com:zed-0xff/lobotomy.git
  cd lobotomy
  sh install_gems.sh
  apt-get install pygments
</pre>
3. pygments - это библиотека раскраски тэгов &lt;code&gt;, есть в портах/пакетах любого *nix дистра, ставить средствами дистра

Преимущества
============

1. Легкость
2. Отсутствие привязки к какой-либо платформе или фреймворку
3. Надежность хранения статей

---

* сайт статический
* платформа [nanoc](http://nanoc.stoneship.org/docs/1-introduction/)
* выкатывается по ssh ключам
* `rake posts:new` - создание нового поста (по дефолту в markdown, но можно переименовать ручками в textile/erb/html)
* `rake deploy` - выкатывание сайта на сервер
* `rake server` - запустить локальный сервер на 3000 порту
* `rake` - скомпилировать контент из `/content` в html в `/output`
* для раскраски кода **на клиенте** нужно установить [pygments](http://pygments.org/) 


Credits
========

* http://nanoc.stoneship.org/
* thanks to http://metaskills.net/ for design
