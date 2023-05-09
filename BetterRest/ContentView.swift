//
//  ContentView.swift
//  BetterRest
//
//  Created by GANDA on 09/05/23.
//

import SwiftUI
import CoreML

struct ContentView: View {
    static var defaultWakeTime: Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date.now
    }

    static let maxCup = 20

    static var cupLabel: [Int: String] {
        return Dictionary(uniqueKeysWithValues: (0...maxCup).map { cupCount in
            let label = cupCount == 1 ? "1 cup" : "\(cupCount) cups"
            return (cupCount, label)
        })
    }

    @State private var wakeUp = defaultWakeTime
    @State private var sleepAmount = 8.0
    @State private var coffeeAmount = 1

    @State private var recommendedBedtime = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker("Please enter a time", selection: $wakeUp, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.wheel)
                        .onChange(of: wakeUp, perform: { _ in
                            calculateBedtime()
                        })

                    Text(recommendedBedtime)
                        .font(.title3.bold())

                } header: {
                    Text("When do you want to wake up")
                }

                Section {
                    Stepper("\(sleepAmount.formatted()) hours", value: $sleepAmount, in: 4...12, step: 0.25)
                } header: {
                    Text("Desired amount of sleep")
                }

                Section {
                    Picker("Number of cups", selection: $coffeeAmount) {
                        ForEach(0...Self.maxCup, id: \.self) { cupCount in
                            Text(Self.cupLabel[cupCount, default: ""])
                        }
                    }
                    .pickerStyle(.wheel)
                } header: {
                    Text("Daily coffee intake")
                }
            }
            .navigationTitle("BetterRest")
            .onAppear {
                calculateBedtime()
            }
        }
    }

    func calculateBedtime() {
        do {
            let config = MLModelConfiguration()
            let model = try SleepCalculator(configuration: config)

            let components = Calendar.current.dateComponents([.hour, .minute], from: wakeUp)
            let hour = (components.hour ?? 0) * 60 * 60
            let minute = (components.minute ?? 0) * 60

            let prediction = try model.prediction(wake: Double(hour + minute), estimatedSleep: sleepAmount, coffee: Double(coffeeAmount))

            let sleepTime = wakeUp - prediction.actualSleep

            recommendedBedtime = "Your ideal bedtime is at " + sleepTime.formatted(date: .omitted, time: .shortened)
        } catch {
            recommendedBedtime = "Sorry, there was a problem calculating your bedtime."
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
