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
    public init(interval: DateInterval,  mode: CalenderMode, @ViewBuilder content: @escaping (Date) -> DateView) {
        self.viewModel = .init(interval: interval, mode: mode)
        self.content = content
    }
    
    var viewModel: DateGridViewModel
    let content: (Date) -> DateView
    @State var selectedMonth = Date.getDate(from: "\(Calendar.current.component(.year, from: Date())) \(Calendar.current.component(.month, from: Date())) 01")!
    @State private var calculatedCellSize: CGSize = .init(width: 1, height: 1)
    @State var index = 1
    
    let windowWidth = UIScreen.main.bounds.width
    
    public var body: some View {
        
        if #available(iOS 14.0, *) {
            VStack {
                    Text(DateFormatter.monthAndYear.string(from: selectedMonth))
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.vertical)
                        .padding(.leading)
                HStack {
                    ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { item in
                        Text(item)
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(8)
                    }
                }
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
                                        
                                    } else {
                                        content(date).hidden()
                                    }
                                }
                            }
                            //                        .padding(.vertical, 5)
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
            }
        } else {
            VStack{
                HStack {
                    Text(DateFormatter.monthAndYear.string(from: selectedMonth))
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.vertical)
                        .padding(.leading)
                    Spacer()
                }
                HStack {
                    ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { item in
                        Text(item)
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(8)
                    }
                }
                ModelPages(viewModel.mainDatesOfAPage, currentPage: $index, hasControl: false) { pageIndex, month in
                    VStack {
                        let daysForMonth = viewModel.days(for: month)
                        ForEach(0 ..< numberOfDayasInAWeek, id: \.self) { i in
                            HStack {
                                ForEach( (i * numberOfDayasInAWeek) ..< (i * numberOfDayasInAWeek + numberOfDayasInAWeek), id: \.self) { j in
                                    Spacer()
                                    if j < daysForMonth.count {
                                        if viewModel.calendar.isDate(daysForMonth[j], equalTo: month, toGranularity: .month) {
                                            content(daysForMonth[j]).id(daysForMonth[j])
                                                .background(
                                                    GeometryReader(){ proxy in
                                                        Color.clear
                                                            .onAppear(){
                                                                calculatedCellSize = proxy.size
                                                            }
                                                    }
                                                )
                                            
                                        } else {
                                            content(daysForMonth[j]).hidden()
                                        }
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .frame(height: tabViewHeight, alignment: .center)
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
            
            DateGrid(interval: .init(start: Date.getDate(from: "2020 01 11")!, end: Date.getDate(from: "2020 12 11")!), mode: .month(estimateHeight: 400)) { date in
                
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
