require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'
require 'mail'


#veritabanı oluşturma fonksiyonu
def create_database
  $database= SQLite3::Database.open 'databse.db'
  $database.execute "CREATE TABLE IF NOT EXISTS admin(id INTEGER PRIMARY KEY AUTOINCREMENT,isim TEXT,soyisim TEXT,username TEXT,password TEXT,resim TEXT,email TEXT)"
  $database.execute "CREATE TABLE IF NOT EXISTS ogrenci(id INTEGER PRIMARY KEY AUTOINCREMENT,isim TEXT,soyisim TEXT,email TEXT,password TEXT,resim TEXT,telefon TEXT,tc TEXT,donem TEXT,okulNo TEXT)"
  $database.execute "CREATE TABLE IF NOT EXISTS dersler(id INTEGER PRIMARY KEY AUTOINCREMENT,dersAd TEXT,dersKod TEXT,kredi INTEGER,uygulama TEXT,teori TEXT,akts INTEGER,bolumAd TEXT,donemBilgisi TEXT)"
  $database.execute "CREATE TABLE IF NOT EXISTS secili_dersler(id INTEGER PRIMARY KEY AUTOINCREMENT,ogrenci_id INTEGER,ders_id TEXT)"
  $database.execute "CREATE TABLE IF NOT EXISTS notlar(id INTEGER PRIMARY KEY AUTOINCREMENT,ogrenci_id INTEGER,ders_id TEXT,vize TEXT,final TEXT,harf TEXT,durum INTEGER)"

end

#genel ayarlar
set :session_secret, 'secret'
set :views, File.dirname(__FILE__) + '/template'
set :public_folder => "static"
set :root ,File.dirname(__FILE__)

#veritbanı oluşturması için fonksiyonumuzu çağırdık
create_database

$database= SQLite3::Database.open 'databse.db'
$admin="null"
$hata=""
$user="null"

$ogrenci_id=-1


get '/' do
  @hata=$hata
  $hata=""
  erb :login
end
get '/home' do
  if $user=="null"
    redirect '/'
  end
  @user=$database.execute "SELECT * FROM ogrenci WHERE id='#{$user}'"
  notlar=$database.execute "SELECT * FROM notlar WHERE ogrenci_id='#{$user}'"
  @not_list=[]
  for i in notlar
    tut=$database.execute "SELECT * FROM dersler WHERE id='#{i[2]}'"
    @not_list.push [i,tut[0]]
  end

  @secilen_dersler=$database.execute "SELECT * FROM secili_dersler WHERE ogrenci_id='#{$user}'"
  @tum_dersler=$database.execute "SELECT * FROM dersler"

  list=[]
  for i in @secilen_dersler
    list=i[2].split(",")
  end

  @alinmayan_dersler=[]
  @tum_dersler.each do |x|
    kontrol=true
    list.each do |y|
      if x[0].to_i==y.to_i
        kontrol=false
      end
    end
    if kontrol
      @alinmayan_dersler.push x
    end
  end

  print @alinmayan_dersler
  erb :index
end


get '/notlarim' do
  if $user=="null"
    redirect '/'
  end
  @user=$database.execute "SELECT * FROM ogrenci WHERE id='#{$user}'"
  notlar=$database.execute "SELECT * FROM notlar WHERE ogrenci_id='#{$user}'"
  @not_list=[]
  for i in notlar
    tut=$database.execute "SELECT * FROM dersler WHERE id='#{i[2]}'"
    @not_list.push [i,tut[0]]
  end
  erb :notlarim
end

get '/ders-kaydi' do
  if $user=="null"
    redirect '/'
  end
  @kontrol=$database.execute "SELECT * FROM secili_dersler WHERE ogrenci_id='#{$user}'"
  @user=$database.execute "SELECT * FROM ogrenci WHERE id='#{$user}'"
  @dersler=$database.execute "SELECT * FROM dersler WHERE donemBilgisi='#{@user[0][8]}'"

  erb :ders_kaydi
end

get '/admin' do
  if $admin == "null"
    redirect '/admin-login'
  end

  @admin=$database.execute "SELECT * FROM admin WHERE id='#{$admin}'"

  @ogrenci=$database.execute "SELECT * FROM ogrenci"

  erb :admin
  end

get '/ogrenci-not/:id' do
  if $admin == "null"
    redirect '/admin-login'
  end
  $ogrenci_id=params[:id]
  secili_dersler=$database.execute "SELECT * FROM secili_dersler WHERE ogrenci_id='#{params[:id]}'"
  list=[]
  for i in secili_dersler
    list=i[2].split(",")
  end
  @dersler=[]
  for i in list
    tut=$database.execute "SELECT * FROM dersler WHERE id='#{i}'"
    @dersler.push tut[0]
  end
  @admin=$database.execute "SELECT * FROM admin WHERE id='#{$admin}'"
  @ogrenci=$database.execute "SELECT * FROM ogrenci"
  erb :ogrenci_not
end

get '/admin/tum-dersler' do
  if $admin == "null"
    redirect '/admin-login'
  end

  @admin=$database.execute "SELECT * FROM admin WHERE id='#{$admin}'"

  @dersler=$database.execute "SELECT * FROM dersler"

  puts @dersler
  erb :tum_dersler
end

get '/admin-login' do
  @hata=$hata
  $hata=""
  erb :admin_login
end

get '/admin-logout' do
  $admin="null"
  redirect '/admin'
end

get '/logout' do
  $user="null"
  redirect '/'
end

get '/admin/ogrenci-ekle' do

  if $admin == "null"
    redirect '/admin-login'
  end

  @admin=$database.execute "SELECT * FROM admin WHERE id='#{$admin}'"
  erb :ogrenci_ekle
end

get '/admin/ders-ekle' do
  if $admin == "null"
    redirect '/admin-login'
  end
  @admin=$database.execute "SELECT * FROM admin WHERE id='#{$admin}'"
  erb :ders_ekle
end


post '/admin-login' do
  @database= SQLite3::Database.open 'databse.db'
  user=@database.execute "SELECT * FROM admin WHERE username='#{params['username']}' and password='#{params['password']}'"
  if user.length >0
    $admin=user[0][0]
    redirect '/admin'
  else
    $hata="Kullanıcı adı veya parola yanlış"
    redirect '/admin-login'
  end
end

post "/ogrenci-sil" do
  id=params["id"]
  $database.execute "DELETE FROM ogrenci WHERE id='#{id}'"
  redirect '/admin'
end

post '/ogrenci-duzenle' do
  $database.execute "UPDATE ogrenci SET isim='#{params["isim"]}',soyisim='#{params["soyisim"]}',email='#{params["email"]}',password='#{params["password"]}',tc='#{params["tc"]}',telefon='#{params["tel"]}',okulNo='#{params['okulNo']}',donem='#{params['donem']}' WHERE id='#{params["id"]}'"
  redirect '/admin'
end

post '/admin/ogrenci-ekle' do

  ad=params["isim"]
  soyisim=params["soyisim"]
  tc=params["tc"]
  email=params["email"]
  password=params["password"]
  tel=params["tel"]
  donem=params["donem"]
  okulNo=params["okulNo"]


  @filename = params[:file][:filename]
  file = params[:file][:tempfile]
  name= @filename.split(//)
  isim=""
  for i in name
    if i=="."
      break
    end
    isim+=i
  end
  dosya_adi=@filename.gsub(isim,tc)
  File.open("static/images/ogrenci/#{dosya_adi}", 'wb') do |f|
    f.write(file.read)
  end
  $database.execute "INSERT INTO ogrenci('isim', 'soyisim', 'email', 'password', 'resim', 'telefon', 'tc','donem','okulNo') VALUES ('#{ad}','#{soyisim}','#{email}','#{password}','#{dosya_adi}','#{tel}','#{tc}','#{donem}','#{okulNo}')"

  Mail_api.new.mail "Trakya OBS için giriş şifreniz\nşifre: #{password}",email
  redirect '/admin/ogrenci-ekle'
end

post '/ders-duzenle' do
  $database.execute "UPDATE dersler SET dersAd='#{params['dersAd']}',dersKod='#{params['dersKod']}',kredi='#{params['kredi']}',uygulama='#{params['uygulama']}',teori='#{params['teori']}',akts='#{params['akts']}',bolumAd='#{params['bolumAd']}',donemBilgisi='#{params['donem']}' WHERE id='#{params['id']}'"
  redirect '/admin/tum-dersler'
end


post '/ders-sil' do
  id=params["id"]
  $database.execute "DELETE FROM dersler WHERE id='#{id}'"
  redirect '/admin/tum-dersler'
end


post '/admin/ders-ekle' do
  dersAd=params["dersAd"]
  dersKodu=params["dersKodu"]
  kredi=params["kredi"]
  uygulama=params["uygulama"]
  teori=params["teori"]
  akts=params["akts"]
  bolumAd=params["bolumAd"]
  donem=params["donem"]

  $database.execute "INSERT INTO dersler('dersAd', 'dersKod', 'kredi', 'uygulama', 'teori', 'akts', 'bolumAd','donemBilgisi') VALUES ('#{dersAd}','#{dersKodu}','#{kredi}','#{uygulama}','#{teori}','#{akts}','#{bolumAd}','#{donem}')"
  redirect '/admin/ders-ekle'
end


post '/login' do
  user= $database.execute "SELECT * FROM ogrenci WHERE tc='#{params['username']}' and password='#{params['password']}'"
  if user.length >0
    $user=user[0][0]
    redirect '/home'
  else
    $hata="Kullanıcı adı veye parola yanlış."
    redirect '/'
  end
end


post '/ders-secimi' do
  ders=params["dersId"].to_s
  kontrol=$database.execute "SELECT * FROM secili_dersler WHERE ogrenci_id='#{$user}'"

  if kontrol.length ==0
    $database.execute "INSERT INTO secili_dersler('ogrenci_id','ders_id') VALUES('#{$user}','#{ders}')"
  else
    $database.execute "UPDATE secili_dersler SET ogrenci_id='#{$user}',ders_id='#{ders}' WHERE ogrenci_id='#{$user}'"
  end
  redirect '/home'
end


post '/not-girisi' do
  id=params['id']
  vize=params['vize']
  final=params['final']
  harf=params['harf']
  durum=params['durum']
  $database.execute "INSERT INTO notlar('ogrenci_id','ders_id','vize','final','harf','durum') VALUES('#{$ogrenci_id}','#{id}','#{vize}','#{final}','#{harf}','#{durum}')"
  redirect back
end



class Mail_api
  def mail(body,to)
    options = { :address              => "smtp.gmail.com",
                :port                 => 587,
                :domain               => 'your.host.name',
                :user_name            => 'username',
                :password             => 'password',
                :authentication       => 'plain',
                :enable_starttls_auto => true  }

    Mail.defaults do
      delivery_method :smtp, options
    end

    Mail.deliver do
      to to
      from 'ersintarik89@gmail.com'
      subject 'Trakya OBS. '
      body body
    end
  end
end

