ExUnit.start()
Faker.start()

Path.wildcard(Path.join(__DIR__, "test_support/**/*.ex"))
|> Enum.sort()
|> Enum.each(&Code.require_file/1)
