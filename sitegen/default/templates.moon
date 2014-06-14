
index = [==[<!DOCTYPE HTML>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>$title</title>
  $each{stylesheets, "url"}[[<link rel="stylesheet" href="$url" />
]]
  $each{javascripts, "url"}[[<script type="text/javascript" src="$url"></script>
]]
</head>
<body>
  $body
</body>
</html>
]==]

{
  :index
}
