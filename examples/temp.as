import("http")

asynchroniczna funkcja pobierz_dane(url) {
    proba {
        zwroc Http.get_json(url)
    } zlap (e) {
        pokazl "Sieć padła: #{e["wiadomosc"]}"
        zwroc nic
    }
}

asynchroniczna funkcja main() {
    niech wyniki = czekaj Obietnica.wszystkie([
        uruchom_rownolegle(fn() { czekaj pobierz_dane("https://jsonplaceholder.typicode.com/users/1") }),
        uruchom_rownolegle(fn() { czekaj pobierz_dane("https://jsonplaceholder.typicode.com/posts/1") })
    ])

    niech udane = wyniki.filtruj(fn(v) { v != nic })
    pokazl wyniki
    pokazl "Pobrano #{udane.dlg()} z #{wyniki.dlg()} zasobów"
}

uruchom(main)