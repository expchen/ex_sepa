ExUnit.start()
Faker.start()

__DIR__
|> Path.join("test_support/**/*.ex")
|> Path.wildcard()
|> Enum.sort()
|> Enum.each(&Code.require_file/1)
