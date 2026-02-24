import Foundation

struct LocationData {
    static let shared = LocationData()
    
    let availableCountries = [
        "Spain", "Italy", "Germany", "France", "United Kingdom",
        "Argentina", "Australia", "Austria", "Bahrain", "Belgium", "Brazil",
        "Canada", "Chile", "China", "Colombia", "Czech Republic", "Denmark",
        "Egypt", "Finland", "Greece", "Hong Kong", "Hungary", "India",
        "Indonesia", "Ireland", "Israel", "Japan", "Jordan", "Kuwait",
        "Lebanon", "Malaysia", "Mexico", "Morocco", "Netherlands", "New Zealand",
        "Norway", "Oman", "Peru", "Philippines", "Poland", "Portugal",
        "Qatar", "Romania", "Saudi Arabia", "Singapore", "South Korea", "Sweden",
        "Switzerland", "Taiwan", "Thailand", "Tunisia", "Turkey",
        "United Arab Emirates", "United States", "Vietnam"
    ]
    
    let citiesByCountry: [String: [String]] = [
        "Italy": ["Milan", "Rome", "Turin", "Florence", "Naples", "Bologna", "Venice", "Genoa", "Verona", "Palermo"],
        "Spain": ["Madrid", "Barcelona", "Valencia", "Seville", "Bilbao", "Malaga", "Zaragoza", "Murcia", "Palma"],
        "Germany": ["Berlin", "Munich", "Frankfurt", "Hamburg", "Cologne", "Düsseldorf", "Stuttgart", "Leipzig", "Dresden", "Nuremberg"],
        "France": ["Paris", "Lyon", "Marseille", "Toulouse", "Nice", "Nantes", "Strasbourg", "Bordeaux", "Lille", "Montpellier"],
        "United Kingdom": ["London", "Manchester", "Birmingham", "Edinburgh", "Glasgow", "Bristol", "Leeds", "Liverpool", "Cambridge", "Oxford"],
        "Netherlands": ["Amsterdam", "Rotterdam", "The Hague", "Utrecht", "Eindhoven"],
        "Belgium": ["Brussels", "Antwerp", "Ghent", "Bruges", "Leuven"],
        "Switzerland": ["Zurich", "Geneva", "Basel", "Bern", "Lausanne"],
        "Austria": ["Vienna", "Salzburg", "Innsbruck", "Graz", "Linz"],
        "Portugal": ["Lisbon", "Porto", "Braga", "Coimbra", "Faro"],
        "Poland": ["Warsaw", "Krakow", "Wroclaw", "Gdansk", "Poznan"],
        "Sweden": ["Stockholm", "Gothenburg", "Malmö", "Uppsala", "Lund"],
        "Norway": ["Oslo", "Bergen", "Trondheim", "Stavanger"],
        "Denmark": ["Copenhagen", "Aarhus", "Odense", "Aalborg"],
        "Finland": ["Helsinki", "Espoo", "Tampere", "Turku", "Oulu"],
        "Ireland": ["Dublin", "Cork", "Galway", "Limerick"],
        "Greece": ["Athens", "Thessaloniki", "Patras", "Heraklion"],
        "Czech Republic": ["Prague", "Brno", "Ostrava", "Pilsen"],
        "Romania": ["Bucharest", "Cluj-Napoca", "Timisoara", "Iasi"],
        "Hungary": ["Budapest", "Debrecen", "Szeged", "Miskolc", "Pécs"],
        "United States": ["New York", "San Francisco", "Los Angeles", "Chicago", "Boston", "Seattle", "Austin", "Miami", "Denver", "Atlanta", "Washington D.C.", "Philadelphia", "San Diego", "Dallas", "Houston"],
        "Canada": ["Toronto", "Vancouver", "Montreal", "Calgary", "Ottawa", "Edmonton"],
        "Mexico": ["Mexico City", "Guadalajara", "Monterrey", "Puebla", "Tijuana", "Cancún"],
        "Brazil": ["São Paulo", "Rio de Janeiro", "Brasília", "Belo Horizonte", "Porto Alegre", "Curitiba", "Salvador", "Recife", "Florianópolis"],
        "Argentina": ["Buenos Aires", "Córdoba", "Rosario", "Mendoza", "Mar del Plata"],
        "Chile": ["Santiago", "Valparaíso", "Concepción", "Viña del Mar"],
        "Colombia": ["Bogotá", "Medellín", "Cali", "Barranquilla", "Cartagena"],
        "Peru": ["Lima", "Arequipa", "Cusco", "Trujillo"],
        "Japan": ["Tokyo", "Osaka", "Kyoto", "Yokohama", "Nagoya", "Fukuoka", "Sapporo", "Kobe"],
        "South Korea": ["Seoul", "Busan", "Incheon", "Daegu", "Daejeon"],
        "China": ["Shanghai", "Beijing", "Shenzhen", "Guangzhou", "Hangzhou", "Chengdu", "Nanjing", "Wuhan", "Xi'an", "Suzhou"],
        "India": ["Mumbai", "Bangalore", "Delhi", "Hyderabad", "Chennai", "Pune", "Kolkata", "Ahmedabad", "Gurgaon", "Noida"],
        "Singapore": ["Singapore"],
        "Hong Kong": ["Hong Kong"],
        "Taiwan": ["Taipei", "Kaohsiung", "Taichung", "Tainan", "Hsinchu"],
        "Indonesia": ["Jakarta", "Surabaya", "Bandung", "Bali", "Medan"],
        "Thailand": ["Bangkok", "Chiang Mai", "Phuket", "Pattaya"],
        "Vietnam": ["Ho Chi Minh City", "Hanoi", "Da Nang", "Hai Phong"],
        "Malaysia": ["Kuala Lumpur", "Penang", "Johor Bahru", "Melaka"],
        "Philippines": ["Manila", "Cebu", "Davao", "Quezon City"],
        "United Arab Emirates": ["Dubai", "Abu Dhabi", "Sharjah"],
        "Israel": ["Tel Aviv", "Jerusalem", "Haifa", "Herzliya"],
        "Saudi Arabia": ["Riyadh", "Jeddah", "Dammam", "Mecca", "Medina"],
        "Bahrain": ["Manama", "Riffa", "Muharraq"],
        "Egypt": ["Cairo", "Alexandria", "Giza", "Sharm El Sheikh", "Luxor"],
        "Jordan": ["Amman", "Aqaba", "Irbid", "Zarqa"],
        "Kuwait": ["Kuwait City", "Hawalli", "Salmiya"],
        "Lebanon": ["Beirut", "Tripoli", "Sidon", "Byblos"],
        "Morocco": ["Casablanca", "Marrakech", "Rabat", "Fez", "Tangier"],
        "Oman": ["Muscat", "Salalah", "Sohar", "Nizwa"],
        "Qatar": ["Doha", "Al Wakrah", "Al Khor"],
        "Tunisia": ["Tunis", "Sfax", "Sousse", "Kairouan"],
        "Turkey": ["Istanbul", "Ankara", "Izmir", "Antalya", "Bursa", "Adana"],
        "Australia": ["Sydney", "Melbourne", "Brisbane", "Perth", "Adelaide", "Canberra", "Gold Coast"],
        "New Zealand": ["Auckland", "Wellington", "Christchurch", "Hamilton", "Queenstown"]
    ]
    
    func citiesForCountry(_ country: String) -> [String] {
        return citiesByCountry[country] ?? []
    }
}
