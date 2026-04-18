modul Test{
  klasa Cos{
    statyczna funkcja moja_funkcja() {
      zwroc "To ze statycznej funkcji"
    }

    funkcja zadziala(){
      zwroc "to powinno zadzialac"
    }
  }
}
pokaz Test::Cos::moja_funkcja()