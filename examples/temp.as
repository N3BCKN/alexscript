klasa Test{
  funkcja konstruktor(){
    niech @gowno = 0
  }

  funkcja dodaj_gowno(n){
    @gowno = @gowno + n
    pokazl @gowno
  }
}


niech x = Test.nowy()


x.dodaj_gowno(5)