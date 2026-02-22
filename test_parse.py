import requests
s = requests.Session()
r = s.post('http://localhost:8010/api/auth/login', json={'username':'admin','password':'LEM2026admin!'})
print('login:', r.status_code, r.text[:200])
if r.status_code != 200:
    r2 = s.post('http://localhost:8010/api/auth/login', json={'username':'admin','password':'admin123'})
    print('login2:', r2.status_code, r2.text[:200])

r3 = s.post('http://localhost:8010/api/diagnostic/parse', json={
    'response_text': 'Przygotowuję się do rozmowy delegującej, analizuję zadanie, określam cele i rezultaty, planuję przebieg rozmowy, wybieram odpowiedni moment na delegowanie. Podczas rozmowy przedstawiam kontekst zadania.',
    'competency': 'delegowanie'
})
print('parse:', r3.status_code)
print('body:', r3.text[:500])
