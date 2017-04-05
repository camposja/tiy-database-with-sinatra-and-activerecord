require 'sinatra'
require 'pg'
require 'sinatra/reloader' if development?
require 'active_record'

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection(
  adapter: "postgresql",
  database: "tiy-database"
)

class Employee < ActiveRecord::Base
  validates :name, presence: true
  validates :position, inclusion: { in: %w{Instructor Student}, message: "%{value} must be Instructor or Student" }

  self.primary_key = "id"
end

# This magic tells Sinatra to close the database connection
# after each request
after do
  ActiveRecord::Base.connection.close
end

get '/' do
  erb :home
end

get '/addpeep' do
  erb :addpeep
end

get '/create_employee' do
  database = PG.connect(dbname:"tiy-database")

  # insert info databse
  name     = params["name"]
  phone    = params["phone"]
  address  = params["address"]
  position = params["position"]
  salary   = params["salary"]
  github   = params["github"]
  slack    = params["slack"]

  database.exec("insert into employees (name, phone, address, position, salary, github, slack) values($1, $2, $3, $4, $5, $6, $7)", [name, phone, address, position, salary, github, slack])

  redirect('/')
end

get '/employees' do
  @employees = Employee.all

  erb :employees
end

get '/displaypeep' do
  database = PG.connect(dbname: "tiy-database")

  id = params["id"]

  employees = database.exec("select * from employees where id =$1", [id])

  @employee = employees.first
  # if
  erb :displaypeep
  # end
end

get '/delete' do
  database = PG.connect(dbname: "tiy-database")

  id = params["id"]

  database.exec("DELETE FROM  employees where id = $1", [id])

  redirect('/employees')
end

get '/editpeep' do
  database = PG.connect(dbname: "tiy-database")

  id = params["id"]

  employees = database.exec("select * from employees where id =$1", [id])

  @employee = employees.first

  erb :editpeep
end

get '/updatepeep' do
  database = PG.connect(dbname: "tiy-database")

  id       = params["id"]
  name     = params["name"]
  phone    = params["phone"]
  address  = params["address"]
  position = params["position"]
  salary   = params["salary"]
  github   = params["github"]
  slack    = params["slack"]

  database.exec("UPDATE employees SET name = $1, phone = $2, address = $3, position = $4, salary = $5, github = $6, slack =$7 WHERE id = $8;", [name, phone, address, position, salary, github, slack, id])

  employees = database.exec("select * from employees where id = $1", [id])

  @employee = employees.first

  erb :employees
end
get '/search' do
  search = params["search"]

  @employees = Employee.where("name like ? or github = ? or slack = ?", "%#{search}%", search, search)

  erb :search
end
