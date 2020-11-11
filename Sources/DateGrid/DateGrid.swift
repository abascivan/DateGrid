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
    public init(interval: DateInterval, selectedMonth: Binding<Date>, selectedDate: Binding<Date>, mode: CalenderMode, @ViewBuilder content: @escaping (Date) -> DateView) {
        self.viewModel = .init(interval: interval, mode: mode)
        self._selectedMonth = selectedMonth
        self.content = content
        self._selectedDate = selectedDate
        
        self.itemCount = viewModel.months.count
        self.contentWidth = (windowWidth)*CGFloat(self.itemCount)
        self.stackOffset = contentWidth/2 - windowWidth/2
    }
    
    var viewModel: DateGridViewModel
    let content: (Date) -> DateView
    let tilePadding: CGFloat = 20
    @Binding var selectedMonth: Date
    @Binding var selectedDate: Date
    @State private var calculatedCellSize: CGSize = .init(width: 1, height: 1)
    
    //PagingScrollView
    @State private var activePageIndex: Int = 0
    
    let windowWidth: CGFloat = UIScreen.main.bounds.width
    
    private let contentWidth : CGFloat
    private let stackOffset : CGFloat // to fix center alignment
    private let itemCount : Int
    private let scrollDampingFactor: CGFloat = 0.66
    @State var currentScrollOffset: CGFloat = 0
    @State private var dragOffset : CGFloat = 0
    
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
                    Text(DateFormatter.monthAndYear.string(from: selectedDate))
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.vertical)
                        .padding(.leading)
                    Spacer()
                }
                HStack {
                    Spacer()
                    ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { item in
                        Text(item)
                            .font(.system(.subheadline, design: .monospaced))
                            .bold()
                        Spacer()
                    }
                }
                //                PagingScrollView(activePageIndex: self.$activePageIndex, itemCount: viewModel.months.count)
                GeometryReader { outerGeometry in
                    HStack {
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
                    .onAppear {
                        self.currentScrollOffset = self.offsetForPageIndex(self.activePageIndex)
                    }
                    .offset(x: self.stackOffset, y: 0)
                    .background(Color.black.opacity(0.00001)) // hack - this allows gesture recognizing even when background is transparent
                    .frame(width: self.contentWidth)
                    .offset(x: self.currentScrollOffset, y: 0)
                    .simultaneousGesture( DragGesture(minimumDistance: 1, coordinateSpace: .local) // can be changed to simultaneous gesture to work with buttons
                                            .onChanged { value in
                                                self.dragOffset = value.translation.width
                                                self.currentScrollOffset = self.computeCurrentScrollOffset()
                                            }
                                            .onEnded { value in
                                                // compute nearest index
                                                let velocityDiff = (value.predictedEndTranslation.width - self.dragOffset)*self.scrollDampingFactor
                                                let newPageIndex = self.indexPageForOffset(self.currentScrollOffset+velocityDiff)
                                                self.dragOffset = 0
                                                withAnimation(.interpolatingSpring(mass: 0.1, stiffness: 20, damping: 100, initialVelocity: 0)){
                                                    self.activePageIndex = newPageIndex
                                                    self.currentScrollOffset = self.computeCurrentScrollOffset()
                                                }
                                            }
                    )
                }
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
    
    //PagingScrollView
    func offsetForPageIndex(_ index: Int)->CGFloat {
        let activePageOffset = CGFloat(index)*(windowWidth)
        
        return -activePageOffset
    }
    
    func indexPageForOffset(_ offset : CGFloat) -> Int {
        guard self.itemCount>0 else {
            return 0
        }
        let offset = self.logicalScrollOffset(trueOffset: offset)
        let floatIndex = (offset)/(windowWidth)
        var computedIndex = Int(round(floatIndex))
        computedIndex = max(computedIndex, 0)
        return min(computedIndex, self.itemCount-1)
    }
    
    /// current scroll offset applied on items
    func computeCurrentScrollOffset()->CGFloat {
        return self.offsetForPageIndex(self.activePageIndex) + self.dragOffset
    }
    
    /// logical offset startin at 0 for the first item - this makes computing the page index easier
    func logicalScrollOffset(trueOffset: CGFloat)->CGFloat {
        return (trueOffset) * -1.0
    }
}

//struct PagingScrollView: View {
//    let items: [AnyView]
//
//
//
//
//
//
//    var body: some View {
//
//    }
//}

struct CalendarView_Previews: PreviewProvider {
    
    @State static var selectedMonthDate = Date()
    @State static var selectedDate = Date()
    @State static var mothsCount: Int = 0
    
    static var previews: some View {
        VStack {
            Text(selectedMonthDate.description)
            WeekDaySymbols()
            
            DateGrid(interval: .init(start: Date.getDate(from: "2020 01 11")!, end: Date.getDate(from: "2020 12 11")!), selectedMonth: $selectedMonthDate, selectedDate: $selectedDate, mode: .month(estimateHeight: 400)) { date in
                
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
