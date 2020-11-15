//
//  FlexibleCalenderView.swift
//  FlexibleCalender
//
//  Created by Heshan Yodagama on 10/22/20.
//

import SwiftUI

public struct DateGrid<DateView>: View where DateView: View {
    
    /// DateStack view
    /// - Parameters:
    ///   - interval:
    ///   - selectedMonth: date relevent to showing month, then you can extract the componnets
    ///   - content:
    public init(interval: DateInterval, selectedMonth: Binding<Date>, selectedDate: Binding<Date>, mode: CalenderMode, mothsCount: Binding<Int>, @ViewBuilder content: @escaping (Date) -> DateView) {
        self.viewModel = .init(interval: interval, mode: mode)
        self._selectedMonth = selectedMonth
        self.content = content
        self._selectedDate = selectedDate
        self._mothsCount = mothsCount
    }
    
    var viewModel: DateGridViewModel
    let content: (Date) -> DateView
    @Binding var selectedMonth: Date
    @Binding var selectedDate: Date
    @Binding var mothsCount: Int
    @State private var calculatedCellSize: CGSize = .init(width: 1, height: 1)
    @State var offset: CGFloat = 0
    @State var index = 0
    
    let windowWidth = UIScreen.main.bounds.width
    
    public var body: some View {
        
        if #available(iOS 14.0, *) {
            TabView(selection: $selectedMonth) {
                
                ForEach(viewModel.mainDatesOfAPage, id: \.self) { month in
                    
                    VStack {
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: numberOfDayasInAWeek), spacing: 0) {
                            
                            ForEach(viewModel.days(for: month), id: \.self) { date in
                                if viewModel.calendar.isDate(date, equalTo: month, toGranularity: .month) {
                                    content(date).id(date)
                                        .background(
                                            GeometryReader(){ proxy in
                                                Color.clear
                                                    .preference(key: MyPreferenceKey.self, value: MyPreferenceData(size: proxy.size))
                                            }
                                        )
                                        .onTapGesture {
                                            selectedDate = date
                                        }
                                    
                                } else {
                                    content(date).hidden()
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        .onPreferenceChange(MyPreferenceKey.self, perform: { value in
                            calculatedCellSize = value.size
                        })
                        .tag(month)
                        //Tab view frame alignment to .Top didnt work dtz y
                        Spacer()
                    }
                    .frame(width: windowWidth)
                }
            }
            .frame(height: tabViewHeight, alignment: .center)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        } else {
            VStack{
                HStack {
                    Text(DateFormatter.monthAndYear.string(from: selectedMonth))
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.vertical)
                        .padding(.leading)
                    Spacer()
//                    Button(action: {
//                        NSLog("prev")
//                        withAnimation(.easeInOut(duration: 1)) {
//                            offset -= windowWidth
//                            selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth)!
//                        }
//                    }) {
//                        Image(systemName: "chevron.left")
//                    }
//                    Button(action: {
//                        NSLog("next")
//                        withAnimation(.easeInOut(duration: 1)) {
//                            offset += windowWidth
//                            selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth)!
//                        }
//                    }) {
//                        Image(systemName: "chevron.right")
//                    }
//                    .padding(.trailing)
                }
//                .frame(width: windowWidth)
                HStack {
                    Spacer()
                    ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { item in
                        Text(item)
                            .font(.system(.subheadline, design: .monospaced))
                            .bold()
                        Spacer()
                    }
                }
//                .frame(width: windowWidth)
//                Pages(currentPage: $index) {
//                     Text("Welcome! This is Page 1")
//                     Text("This is Page 2")
//                     Text("...and this is Page 3")
//                     Circle() // The 4th page is a Circle
//                }
                ModelPages(viewModel.mainDatesOfAPage, currentPage: 0) {currentPage, month in
//                    ForEach(viewModel.mainDatesOfAPage, id: \.self) { month in
                        VStack {
                            let daysForMonth = viewModel.days(for: month)
                            ForEach(0 ..< numberOfDayasInAWeek, id: \.self) { i in
                                HStack {
                                    Spacer()
                                    ForEach( (i * numberOfDayasInAWeek) ..< (i * numberOfDayasInAWeek + numberOfDayasInAWeek), id: \.self) { j in
                                        if j < daysForMonth.count {
                                            if viewModel.calendar.isDate(daysForMonth[j], equalTo: month, toGranularity: .month) {
                                                content(daysForMonth[j]).id(daysForMonth[j])
                                                    .background(
                                                        GeometryReader(){ proxy in
                                                            Color.clear
                                                                .preference(key: MyPreferenceKey.self, value: MyPreferenceData(size: proxy.size))
                                                        }
                                                    )
                                                    .onTapGesture {
                                                        withAnimation(.none){
                                                            selectedDate = daysForMonth[j]
                                                        }
                                                    }

                                            } else {
                                                content(daysForMonth[j]).hidden()
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
//                    }
                }
            }
            .onAppear(){
                mothsCount = viewModel.mainDatesOfAPage.count
            }
        }
    }
    
    //MARK: constant and supportive methods
    private let numberOfDayasInAWeek = 7
    private var tabViewHeight: CGFloat {
        let calculatedTabViewHeightByCalculatedCellHeight = viewModel.mode.calculatedheight(calculatedCellSize.height)
        return max(viewModel.mode.estimateHeight, calculatedTabViewHeightByCalculatedCellHeight) + 10
    }
    
    var weekContentHeight: CGFloat {
        return max(viewModel.mode.estimateHeight, calculatedCellSize.height * 1)
    }
}

struct CalendarView_Previews: PreviewProvider {
    
    @State static var selectedMonthDate = Date()
    @State static var selectedDate = Date()
    @State static var mothsCount: Int = 0
    
    static var previews: some View {
        VStack {
            Text(selectedMonthDate.description)
            WeekDaySymbols()
            
            DateGrid(interval: .init(start: Date.getDate(from: "2020 01 11")!, end: Date.getDate(from: "2020 12 11")!), selectedMonth: $selectedMonthDate, selectedDate: $selectedDate, mode: .month(estimateHeight: 400), mothsCount: $mothsCount) { date in
                
                NoramalDayCell(date: date)
            }
        }
        
    }
}


//Key
fileprivate struct MyPreferenceKey: PreferenceKey {
    static var defaultValue: MyPreferenceData = MyPreferenceData(size: CGSize.zero)
    
    
    static func reduce(value: inout MyPreferenceData, nextValue: () -> MyPreferenceData) {
        value = nextValue()
    }
    
    typealias Value = MyPreferenceData
}

//Value
fileprivate struct MyPreferenceData: Equatable {
    let size: CGSize
    //you can give any name to this variable as usual.
}
