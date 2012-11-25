Сайт Lobotomy Team
-------------

Ставим на локалхост
======================
1. Если хотите доступ на запись - скажите чтобы я (zed) добавил вас в Collaborators этой репы, для этого вам нужен акк на гитхабе (примечание: **форкать эту репу НЕ НУЖНО**)
2. Выполнить следующее
<pre>
  git clone git@github.com:zed-0xff/lobotomy.git
  cd lobotomy
  sh install.sh
</pre>

Пишем врайтап
=============
0. `git pull` чтобы подтянуть все что обновилось в репе
1. `rake writeups:new`
2. Программа спросит <tt>Writeup title</tt> и <tt>Writeup format ([md](http://daringfireball.net/projects/markdown/syntax),[textile](http://www.textism.com/tools/textile/),html,[erb](http://en.wikipedia.org/wiki/ERuby),[haml](http://haml.info/)) (default: md)</tt>
3. Программа запустит ваш любимый `$EDITOR` со свежесозданным файлом
4. Пишем врайтап
5. `rake compile` (или просто `rake`)
6. Радуемся что нет ошибок и проверяем в каталоге `output` что получилось
7. `rake deploy` - деплоим на вебсервер, на вебсервере должен уже быть ваш SSH паблик кей, иначе ничего не выйдет
8. `git commit`, тщательно выбираем что коммитить, `git push`

---

### Примечания

* Для проверки можно запустить локальный `rake server` на порту 3000
* [pygments](http://pygments.org/) - это библиотека раскраски тэгов &lt;code&gt;, есть в портах/пакетах любого *nix дистра, ставить средствами дистра

---

### Преимущества платформы

1. Легкость
2. Отсутствие привязки к какой-либо платформе или фреймворку
3. Надежность хранения статей

### Credits

* http://nanoc.stoneship.org/
* thanks to http://metaskills.net/ for design
