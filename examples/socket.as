# ============================================================================
# test_socket.as — Testy bibliotek SocketTcp, SerwerTcp, SocketUdp, Socket
# ============================================================================
import("socket")
import("czas")

niech testy_ok = 0
niech testy_fail = 0

funkcja test(nazwa, warunek) {
    jesli warunek {
        testy_ok = testy_ok + 1
    } albo {
        pokazl "[FAIL] " + nazwa
        testy_fail = testy_fail + 1
    }
}

# ============================================================================
# 1. SOCKET — STATYCZNE HELPERY
# ============================================================================

niech hostname = Socket.nazwa_hosta()
test("nazwa_hosta — niepusty", hostname.dlg() > 0)

niech ip = Socket.pobierz_adres_ip("localhost")
test("pobierz_adres_ip(localhost)", ip == "127.0.0.1")

niech port = Socket.wolny_port()
test("wolny_port — > 0", port > 0)
test("wolny_port — < 65536", port < 65536)
test("czy_port_wolny — wolny port", Socket.czy_port_wolny(port))

niech adresy = Socket.pobierz_wszystkie_adresy("localhost")
test("pobierz_wszystkie_adresy — > 0", adresy.dlg() > 0)

# ============================================================================
# 2. SERWER TCP — TWORZENIE I ZAMYKANIE
# ============================================================================

niech port_srv = Socket.wolny_port()
niech srv = SerwerTcp.nowy(port_srv)
test("SerwerTcp — otwarty", srv.czy_zamkniety() == falsz)
test("port() — poprawny", srv.port() == port_srv)

niech addr = srv.adres_lokalny()
test("adres_lokalny — port OK", addr["port"] == port_srv)

test("port zajęty po otwarciu", Socket.czy_port_wolny(port_srv) == falsz)

srv.zamknij()
test("serwer zamknięty", srv.czy_zamkniety())

Czas.uspij(0.1)
test("port wolny po zamknięciu", Socket.czy_port_wolny(port_srv))

# ============================================================================
# 3. TCP KLIENT-SERWER — KOMUNIKACJA
# ============================================================================

niech pt = Socket.wolny_port()
niech s = SerwerTcp.nowy(pt)
niech kl = SocketTcp.nowy("127.0.0.1", pt)
test("klient połączony", kl.czy_zamkniety() == falsz)

niech zdalny = kl.adres_zdalny()
test("adres_zdalny — port serwera", zdalny["port"] == pt)

niech pol = s.akceptuj()
test("akceptuj — OK", pol.czy_zamkniety() == falsz)

# Klient → serwer
kl.wyslij("Witaj serwer!")
niech odebrane = pol.odbierz(1024)
test("send/recv — dane", odebrane == "Witaj serwer!")

# Serwer → klient
pol.wyslij("Witaj kliencie!")
niech odpowiedz = kl.odbierz(1024)
test("recv odpowiedź", odpowiedz == "Witaj kliencie!")

niech lok = kl.adres_lokalny()
test("adres_lokalny klienta", lok["port"] > 0)

kl.zamknij()
pol.zamknij()
s.zamknij()
test("klient zamknięty", kl.czy_zamkniety())
test("połączenie zamknięte", pol.czy_zamkniety())
test("serwer zamknięty", s.czy_zamkniety())

# ============================================================================
# 4. TCP — LINIE
# ============================================================================

niech pl = Socket.wolny_port()
niech s2 = SerwerTcp.nowy(pl)
niech kl2 = SocketTcp.nowy("127.0.0.1", pl)
niech pol2 = s2.akceptuj()

kl2.wyslij_linie("linia1")
kl2.wyslij_linie("linia2")
kl2.zamknij_zapis()

niech l1 = pol2.czytaj_linie()
niech l2 = pol2.czytaj_linie()
test("linia1", l1 == "linia1")
test("linia2", l2 == "linia2")

kl2.zamknij()
pol2.zamknij()
s2.zamknij()

# ============================================================================
# 5. TCP — WIELOKROTNA WYMIANA
# ============================================================================

niech pm = Socket.wolny_port()
niech sm = SerwerTcp.nowy(pm)
niech km = SocketTcp.nowy("127.0.0.1", pm)
niech polm = sm.akceptuj()

km.wyslij("msg1")
test("multi msg1", polm.odbierz(1024) == "msg1")

polm.wyslij("ack1")
test("multi ack1", km.odbierz(1024) == "ack1")

km.wyslij("msg2")
test("multi msg2", polm.odbierz(1024) == "msg2")

km.zamknij()
polm.zamknij()
sm.zamknij()

# ============================================================================
# 6. UDP
# ============================================================================

niech pu = Socket.wolny_port()
niech udp_srv = SocketUdp.nowy()
udp_srv.zwiaz(pu)
test("UDP zwiazany", udp_srv.czy_zamkniety() == falsz)

niech udp_kl = SocketUdp.nowy()
udp_kl.wyslij("UDP dane", "127.0.0.1", pu)

niech wynik = udp_srv.odbierz(1024)
test("UDP dane", wynik["dane"] == "UDP dane")
test("UDP adres", wynik["adres"] == "127.0.0.1")
test("UDP port > 0", wynik["port"] > 0)

udp_kl.zamknij()
udp_srv.zamknij()
test("UDP klient zamknięty", udp_kl.czy_zamkniety())
test("UDP serwer zamknięty", udp_srv.czy_zamkniety())

# ============================================================================
# 7. UDP — POLACZ + WYSLIJ_POLACZONY
# ============================================================================

niech pu2 = Socket.wolny_port()
niech udp_s2 = SocketUdp.nowy()
udp_s2.zwiaz(pu2)

niech udp_k2 = SocketUdp.nowy()
udp_k2.polacz("127.0.0.1", pu2)
udp_k2.wyslij_polaczony("polaczony msg")

niech w2 = udp_s2.odbierz(1024)
test("UDP polaczony — dane", w2["dane"] == "polaczony msg")

udp_k2.zamknij()
udp_s2.zamknij()

# ============================================================================
# 8. TCP OPCJE
# ============================================================================

niech po = Socket.wolny_port()
niech so = SerwerTcp.nowy(po)
niech ko = SocketTcp.nowy("127.0.0.1", po)
niech polo = so.akceptuj()

test("keepalive", ko.ustaw_keepalive(prawda))
test("nodelay", ko.ustaw_nodelay(prawda))
test("flush", ko.flush())

ko.zamknij()
polo.zamknij()
so.zamknij()

# ============================================================================
# PODSUMOWANIE
# ============================================================================

pokazl ""
pokazl "================================"
pokazl "WYNIKI TESTÓW BIBLIOTEKI SOCKET"
pokazl "================================"
pokazl "Przeszło: " + testy_ok
pokazl "Nie przeszło: " + testy_fail
pokazl "Razem: " + (testy_ok + testy_fail)
pokazl "================================"

jesli testy_fail == 0 {
    pokazl "WSZYSTKIE TESTY PRZESZŁY!"
} albo {
    pokazl "UWAGA: " + testy_fail + " testów nie przeszło!"
}
