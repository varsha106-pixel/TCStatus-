//
//  ContentView.swift
//  TCStatus
//
//  Created by Varsha Jawadi on 6/16/25.
//

import SwiftUI


//allowing userinput and list of registered court names to be accessed across pages
class SharedData: ObservableObject {
    //stores userinput and registeredcourts array and empty or in use button status
    
    //@published -> SwiftUI views observing will automatically update when it changes
    //this variable holds the status empty or in use so the court remains that status even if the app is exited
    @Published var buttonStates: [String: String] = [:] {
        didSet {
            saveButtonStates()
        }
    }
    @Published var userInput: String = ""
    @Published var registeredCourts: [Court] = [] {
  //when registeredcourts is changed didSet is triggered and saveCourts is called calling saveCourts saves the updated array to disk
            didSet {
                saveCourts()
            }
        }
        //the key under which array is stored in UserDefaults (built in Swift class that lets you store bits of data on the user's device) best for booleans, strings, numbers, arrays,dates, codable types
        private let courtsKey = "registeredCourts"

        init() {
            //first loads the courts previously saved from UserDefaults
            //then removes any duplicate addresses
            loadCourts()
            removeDuplicateAddresses()
            loadButtonStates()
        }
// encodes registeredCourts into JSON (javascript object notation) used to store and exchange structured data
    //converts array of Court objects into binary JSON Data. Internally, the array is transformed into a JSON-formatted structure.
    //[
    //{
     // "courtAddress": "123 Lane",
//        "courtName": "Main Court",
//      "numberOfCourts": "3",
//      "id": "A-UUID-HERE"
//    }
//  ]
    //This JSON structure is then turned into a Data object (a sequence of bytes).
//    let data: Data = try JSONEncoder().encode(registeredCourts)
    //Data is what gets stored in UserDefaults.
   
        func saveCourts() {
            if let encoded = try? JSONEncoder().encode(registeredCourts) {
                //stores it in UserDefaults under the key "registeredCourts"
                UserDefaults.standard.set(encoded, forKey: courtsKey)
            }
        }

        func loadCourts() {
            //retrieves saved JSON data from UserDefaults
            if let data = UserDefaults.standard.data(forKey: courtsKey),
               //decodes it back into an array of objects
               let decoded = try? JSONDecoder().decode([Court].self, from: data) {
                //loads it back into registeredCourts
                registeredCourts = decoded
            }
        }
    //gets rid of any duplicate addresses in array
    func removeDuplicateAddresses() {
        var seenAddresses = Set<String>()//set
        //looks through courts in registered courts
        // .filter -> if returns false removes court from array
        registeredCourts = registeredCourts.filter { court in
            //checks if address is in seen addresses
            if seenAddresses.contains(court.courtAddress)
                
            {
                return false
            }
            //adds it if it is not there
            else {
                seenAddresses.insert(court.courtAddress)
                return true
            }
        }
    }
    //key for accessing button state data
    private let buttonStatesKey = "buttonStates"
//same functioning as the saveCourts and loadCourts methods
    func saveButtonStates() {
        if let encoded = try? JSONEncoder().encode(buttonStates) {
            UserDefaults.standard.set(encoded, forKey: buttonStatesKey)
        }
    }

    func loadButtonStates() {
        if let data = UserDefaults.standard.data(forKey: buttonStatesKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            buttonStates = decoded
        }
    }
    
}
//Court object with address, name, number of court

struct Court: Identifiable, Codable, Equatable {
    //gives a court a unique identification
    var id = UUID()
    var courtAddress: String
    var courtName: String
    var numberOfCourts: String
}


//initial page
struct ContentView: View {
    // instance variable for sharedData allows it to be observed through environmetobject
    @EnvironmentObject var sharedData: SharedData
    
    //instance variable to check if button is pressed
    @State private var navigate: Bool = false
    var body: some View {
        //ability to navigate to another page
        NavigationStack{
            //ability to scroll
            ScrollView{
                VStack {
                    Spacer()
                        
                    Text("TCStatus")//app title
                        .font(.largeTitle)//larger text
                    Text("Search for and add public courts near you to mark them as available or not! The court name is the name of the park or facility containing the court. ")
                        .multilineTextAlignment(.center)
                    TextField("search court name...",text: $sharedData.userInput)// text inside input box
                        .overlay(
                               RoundedRectangle(cornerRadius: 8)
                                   .stroke(Color.green, lineWidth: 3) //  customize border color and thickness
                           )
                        .frame(height: 700)//alignment keeps the submit and searchbox lower
                    //text box style
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .padding(.horizontal)
                   
                    //button text
                    Button("Submit") {
                                    navigate = true
                                }
                                //button style and position
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .padding(.top, -300)
                    
                                
                    Spacer()
                }
                //navigates to results when button is pressed
                .navigationDestination(isPresented: $navigate) {
                                ResultsPage()
                        .environmentObject(sharedData)
                     
                            }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // makes the VStack fill space
                
                       

                
            
            }
            }
            
       
        
        
    }
}

#Preview {
    //adjusts preview to navigation
    NavigationStack {
        ContentView()
            .environmentObject(SharedData())//injects shared data so view has it in preview
           
    }
}

//court results page
struct ResultsPage: View {
    // instance variable for sharedData that is injected
    //allows to observe sharedData
    @EnvironmentObject var sharedData: SharedData
    
    //bool whether to navigate to court entry or not
    @State private var navigateToCourtEntry: Bool = false
    //bool whether to navigate to search page or not
    @State private var navigateToSearch: Bool = false
    //var for when court button is clicked
    //UUID makes it unique for each court
    @State private  var showCourtButtons: [UUID: Bool] = [:]
    //var for each button to update status
    @State private var buttonStates: [String: String] = [:]
    
    var body: some View {
        //ability to navigate to another page
        NavigationStack{
            //ability to scroll
            ScrollView{
                VStack{
                    
                    
                    //checking through the registered courts for all the courts that have the same name as the user inputted not case sensitive
                    ForEach(sharedData.registeredCourts){court in
                        if court.courtName.caseInsensitiveCompare(sharedData.userInput) == .orderedSame  {
                            Spacer()
                            //creating buttons for every registered court with that name
                            Button(court.courtName) {
                                showCourtButtons[court.id] = !(showCourtButtons[court.id] ?? false)
                            }
                            //button style and position
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            Spacer()
                            //checking if button is clicked, number of courts is an integer
                            if showCourtButtons[court.id] == true,let courtCount = Int(court.numberOfCourts){
                                //checking if the courtName is the same one as userInput not case sensitive
                                    if court.courtName.caseInsensitiveCompare(sharedData.userInput) == .orderedSame {
                                        //displays court address in case there is multiple courts with same name different address
                                       Text("\(court.courtAddress)")
                                        //loops for the number of courts that the park has
                                            ForEach(1..<courtCount+1){ i in
                                                //creates a unique key for each button using the courtID and the index (i)
                                                //necessary so only the button clicked changes status and not all buttons
                                                let key = "\(court.id.uuidString)-\(i)"
                                                //sets default to "Empty" for each button and sets unique key to that button
                                                let label = sharedData.buttonStates[key, default: "Empty"]
                                                Button(label){
                                                    //if button is clicked switches that particular button from empty to in use and vice versa
                                                    sharedData.buttonStates[key] = (sharedData.buttonStates[key] == "In Use") ? "Empty" : "In Use"
                                                    
                                                    
                                                }
                                                //button style
                                                .padding()
                                                .background(label == "In Use" ? Color.red : Color.green)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                            }
                                            
                                            
                                            
                                            
                                        }
                                        
                                    }
                                    
                                    
                                
                                
                            }
                           
                            
                            
                        }
                    //button to add a court details for a new
                    //navigates to add new court page
                    
                    Button("click to add new court"){
                        navigateToCourtEntry=true
                        
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                            .navigationDestination(isPresented: $navigateToCourtEntry) {
                                addnewCourtPage()
                                    .environmentObject(sharedData)
                                
                                
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Button("Back to Search Page") {
                        sharedData.userInput = ""
                        navigateToSearch = true
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .navigationDestination(isPresented: $navigateToSearch) {
                        ContentView()
                            .environmentObject(sharedData)
                        
                        
                    }
                    
                    }
                
                
                    
                    
                }
            
            }
                
            }
            
    }

        #Preview {
            NavigationStack {
                ResultsPage()
                //inject so it shows up in preview
                    .environmentObject(SharedData())
                
            }
        }
    
        
        //adding new court page
struct addnewCourtPage: View {
    //allows to observe sharedData
    @EnvironmentObject var sharedData: SharedData
    //court details of new court
    @State private var courtAddress: String = ""
    @State private var courtName: String = ""
    @State private var numberOfCourts: String = ""
    //was the court successfully added or already there or invalid?
    @State private var courtAddedMessageShown = false
    //was this court already there
    @State private var courtRepeated = false
    //what is the name of this court initially
    @State private var repeatedCourtName: String = ""
    //did they press submit
    @State private var submitPressed = false
    //bool whether to navigate to another page or not
    @State private var navigate: Bool = false
    
    
    var body: some View {
        //ability to navigate to another page
        NavigationStack{
            //ability to scroll
            ScrollView{
                VStack{
                    //textboxes for user to enter info of new court they are adding
                    TextField("enter court address",text: $courtAddress)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green, lineWidth: 3) //  customize border color and thickness
                        )
                    TextField("enter court name",text: $courtName)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green, lineWidth: 3) //  customize border color and thickness
                        )
                    TextField("enter number of courts",text: $numberOfCourts)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green, lineWidth: 3) //  customize border color and thickness
                        )
                    //sumbit button adds the court with details to registered courts array
                    
                    Button("Submit") {
                        submitPressed = true
                        //check is numberOfCourts is an integer and that the other field are not empty
                        if let number = Int(numberOfCourts), !courtName.isEmpty, !courtAddress.isEmpty{
                            //creates the newCourt with all details
                            let newCourt = Court(courtAddress: courtAddress, courtName: courtName, numberOfCourts: numberOfCourts)
                            //checks if there is a dupulicate by comparing addresses depsite formatting
                            let isDuplicate = sharedData.registeredCourts.contains(where: {
                                $0.courtAddress.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                                               ==
                                               newCourt.courtAddress.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                                   })
                          
                            //if it isnt already in registeredCourts add it
                            if(!isDuplicate){
                                sharedData.registeredCourts.append(newCourt)
                            }
                            //just in edge case a duplicate does get added (if someone taps really fast or there’s a race condition, the array could (in theory) briefly include the duplicate before it gets saved.) Removes duplicates again
                            sharedData.removeDuplicateAddresses()
                            //if the court is in registeredCOurts it has been successfully added
                            if sharedData.registeredCourts.contains(newCourt){
                                courtAddedMessageShown = true
                                
                            }
                            //if it goes into the if statement it is valid input so if not added it mustve been duplicate find original court name so user knows it is already registered and under what name it's registered
                            else{
                                courtRepeated = true
                                for court in sharedData.registeredCourts{
                                    if court.courtAddress == newCourt.courtAddress{
                                        repeatedCourtName = court.courtName
                                    }
                                }
                            }
                            
                            
                        }
                        
                        
                    }
                    //button style and position
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.top, 100)
                    if courtAddedMessageShown {
                        Text("Court has been added!")
                            .foregroundColor(.green)
                            .padding()
                        
                        
                    }
                    //let user know this court is already registered if it is a duplicate and what the court name is
                    if courtRepeated {
                        Text("This court is already registered as \(repeatedCourtName)")
                            .foregroundColor(.red)
                            .padding()
                        
                        
                    }
                    //if they pressed submit but it did not go into the if statement it mustve been invalid input so error msg for inavlid input
                    if !courtAddedMessageShown && !courtRepeated && submitPressed{
                        Text("Invalid input!").foregroundColor(.red)
                            .padding()
                    }
                    //goes back to the oirginal page when they are done adding a court
                    Button("Back to Search Page")
                    {
                        //clears the input so the search box is now empty ready for a new search
                        sharedData.userInput = ""
                        navigate = true
                        
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                            .navigationDestination(isPresented: $navigate) {
                                ContentView()
                                    .environmentObject(sharedData)
                                
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
                
            }
            
          
}
        #Preview {
            NavigationStack {
                addnewCourtPage()
                //inject so it shows up in preview
                    .environmentObject(SharedData())
                
            }
        }
        
        
