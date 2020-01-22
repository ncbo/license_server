# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
LicensePurpose.create ([
    {name: "Non-Profit Research - Individual", sort_order: 1},
    {name: "Non-Profit Research - Team", sort_order: 2},
    {name: "Host a Public Portal (Research/Non-Profit)", sort_order: 3},
    {name: "Education", sort_order: 4},
    {name: "Non-Profit - Other", sort_order: 5},
    {name: "Commercial - Research", sort_order: 6},
    {name: "Commercial - Managing Semantic Resources", sort_order: 7},
    {name: "Commercial - Host a Public Portal", sort_order: 8},
    {name: "Commercial - Other", sort_order: 9}
])
