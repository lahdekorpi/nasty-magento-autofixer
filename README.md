# nasty-magento-autofixer
A nasty Magento autofixer for [magento/Magento2/#6639](https://github.com/magento/magento2/issues/6639)

A horrible hack that pings some local paths to see that the cached version isn't empty / has the rights DOM elements.

### Absolutely do not use in production

Requires [pup](https://github.com/ericchiang/pup)


# Why?

Here's a copy of the Magento2 issue:

Usually when the configured MySQL server isn't responding or it's giving an error, Magento throws an exception as it should.
However, while our server was running low on RAM and MySQL got killed, I've noticed that at times if the request to the MySQL server dies while receiving data, Magento keeps on going and produces a broken page that then gets cached to the page cache (tested both the built-in cache and Varnish).
In both cases the output was the same. The page has the correct `<head>` with resources etc but the `<title>` and `<body>` have no content. Also, a 200 response is given out.
Testing this is a bit tricky, but I've managed to reproduce by loading a bunch of dummy traffic to / while forcefully killing MySQL.

### Steps to reproduce
1. Default install
2. Use page cache (built-in or Varnish)
3. Generate dummy traffic to /
4. Simulate killing the MySQL server due to memory running out
5. Load /

### Expected result
1. If the connection dies while receiving data, throw an exception and a non 200 HTTP code
2. Contents not getting cached due to an exception / non 200 HTTP code

### Actual result
1. 200 HTTP code
2. Existing but empty `<title>` and `<body>` tags
3. Empty page with just some resources in `<head>` gets cached into built-in cache or Varnish
4. Error is logged (sometimes): `main.CRITICAL: Warning: PDOStatement::execute(): MySQL server has gone away in vendor/magento/zendframework1/library/Zend/Db/Statement/Pdo.php on line 228`
