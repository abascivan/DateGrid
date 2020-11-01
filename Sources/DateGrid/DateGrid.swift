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
    
    let windowWidth = UIScreen.main.bounds.width
    
    public var body: some View {
        
        if #available(iOS 14.0, *) {
            TabView(selection: $selectedMonth) {
                
                ForEach(viewModel.months, id: \.self) { month in
                    
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
                    Text("Month")
                    Spacer()
                    Button(action: {
                        print("prev")
                    }) {
                        Text("prev")
                    }
                    Button(action: {
                        print("prev")
                    }) {
                        Text("next")
                    }
                }
                .background(Color.red)
                .frame(width: windowWidth)
                HStack{
                    ForEach(viewModel.months, id: \.self) { month in
                        VStack {
                            ForEach(0 ..< numberOfDayasInAWeek, id: \.self) { i in
                                HStack {
                                    Spacer()
                                    ForEach( (i * numberOfDayasInAWeek) ..< (i * numberOfDayasInAWeek + numberOfDayasInAWeek), id: \.self) { j in
                                        if j < viewModel.days(for: month).count {
                                            if viewModel.calendar.isDate(viewModel.days(for: month)[j], equalTo: month, toGranularity: .month) {
                                                content(viewModel.days(for: month)[j]).id(viewModel.days(for: month)[j])
                                                    .background(
                                                        GeometryReader(){ proxy in
                                                            Color.clear
                                                                .preference(key: MyPreferenceKey.self, value: MyPreferenceData(size: proxy.size))
                                                        }
                                                    )
                                                    .onTapGesture {
                                                        print(viewModel.days(for: month)[j].day)
                                                        selectedDate = viewModel.days(for: month)[j]
                                                    }
                                                
                                            } else {
                                                content(viewModel.days(for: month)[j]).hidden()
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
            }
                .frame(width: windowWidth * CGFloat(mothsCount))
                .offset(x: windowWidth * CGFloat(mothsCount) / CGFloat(mothsCount))
            .onAppear(){
                mothsCount = viewModel.months.count
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
