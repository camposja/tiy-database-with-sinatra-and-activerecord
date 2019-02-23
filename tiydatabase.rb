require 'sinatra'
require 'pg'
require 'active_record'

# TODO: sinatra reloader not required after sinatra update
# require 'sinatra/reloader' if development?

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

after do
  ActiveRecord::Base.connection.close
end

get '/' do
  erb :home
end

get '/addpeep' do
  @employee = Employee.new

  erb :addpeep
end

get '/create_employee' do
  @employee = Employee.create(params)
  if @employee.valid?
    redirect('/')
  else
    erb :employees_new
  end
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
  erb :displaypeep
end

get '/delete' do
  database = PG.connect(dbname: "tiy-database")
  @employee = Employee.find(params["id"])
  @employee.destroy
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
  @employee = Employee.find(params["id"])
  @employee.update_attributes(params)

    if @employee.valid?
      redirect to("/displaypeep?id=#{@employee.id}")
    else
      erb :employees
    end
end

get '/search' do
  search = params["search"]
  @employees = Employee.where("name like ? or github = ? or slack = ?", "%#{search}%", search, search)
  erb :search
end
