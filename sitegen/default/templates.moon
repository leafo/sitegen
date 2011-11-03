
module ..., package.seeall
export *

index = [==[<!DOCTYPE HTML>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>something: $something</title>
  $each{javascripts, "url"}[[<script type="text/javascript" src="$url"></script>
]]
  $each{stylesheets, "url"}[[<link rel="stylesheet" href="$url" />
]]
</head>
<body>
  $body
</body>
</html>
]==]

