Lobotomy Team
-------------

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
