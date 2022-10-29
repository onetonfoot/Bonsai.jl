using SQLite, Strapping

const db = SQLite.DB()

function seed_database(db)
	categories = [dog, cat, hamster]
	names = ["dom", "bob", "su", "bel"]
	pets = [ Pet(name=rand(names), category=rand(categories)) for _ in 1:5 ]
	# Strapping.deconstruct(pets)
end