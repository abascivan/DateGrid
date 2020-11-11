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
    let tilePadding: CGFloat = 20
    @State private var activePageIndex: Int = 0
    @Binding var selectedMonth: Date
    @Binding var selectedDate: Date
    @Binding var mothsCount: Int
    @State private var calculatedCellSize: CGSize = .init(width: 1, height: 1)
//    @State var offset: CGFloat = 0
    
    let windowWidth: CGFloat = UIScreen.main.bounds.width
    
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
                PagingScrollView(activePageIndex: self.$activePageIndex, itemCount: self.viewModel.months.count ,pageWidth: windowWidth, tileWidth: windowWidth, tilePadding: 0){
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
//                .frame(width: windowWidth * CGFloat(mothsCount))
//                .offset(x: (windowWidth * CGFloat(mothsCount - 1) / 2 - CGFloat(offset)))
            }
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

struct PagingScrollView: View {
    let items: [AnyView]

    init<A: View>(activePageIndex:Binding<Int>, itemCount: Int, pageWidth:CGFloat, tileWidth:CGFloat, tilePadding: CGFloat, @ViewBuilder content: () -> A) {
        let views = content()
        self.items = [AnyView(views)]
        
        self._activePageIndex = activePageIndex
        
        self.pageWidth = pageWidth
        self.tileWidth = tileWidth
        self.tilePadding = tilePadding
        self.tileRemain = 0
        self.itemCount = itemCount
        self.contentWidth = (tileWidth+tilePadding)*CGFloat(self.itemCount)
        
        self.leadingOffset = tileRemain+tilePadding
        self.stackOffset = contentWidth/2 - pageWidth/2 - tilePadding/2
    }
    
    /// index of current page 0..N-1
    @Binding var activePageIndex : Int
    
    /// pageWidth==frameWidth used to properly compute offsets
    let pageWidth: CGFloat
    
    /// width of item / tile
    let tileWidth : CGFloat
    
    /// padding between items
    private let tilePadding : CGFloat
    
    /// how much of surrounding iems is still visible
    private let tileRemain : CGFloat
    
    /// total width of conatiner
    private let contentWidth : CGFloat
    
    /// offset to scroll on the first item
    private let leadingOffset : CGFloat
    
    /// since the hstack is centered by default this offset actualy moves it entirely to the left
    private let stackOffset : CGFloat // to fix center alignment
    
    /// number of items; I did not come with the soluion of extracting the right count in initializer
    private let itemCount : Int
    
    /// some damping factor to reduce liveness
    private let scrollDampingFactor: CGFloat = 0.66
    
    /// current offset of all items
    @State var currentScrollOffset: CGFloat = 0
    
    /// drag offset during drag gesture
    @State private var dragOffset : CGFloat = 0
    
    
    func offsetForPageIndex(_ index: Int)->CGFloat {
        print("offsetForPageIndex tileWidth: \(tileWidth) tilePadding \(tilePadding)")
        let activePageOffset = CGFloat(index)*(tileWidth+tilePadding)
        
        return self.leadingOffset - activePageOffset
    }
    
    func indexPageForOffset(_ offset : CGFloat) -> Int {
        guard self.itemCount>0 else {
            return 0
        }
        let offset = self.logicalScrollOffset(trueOffset: offset)
        let floatIndex = (offset)/(tileWidth+tilePadding)
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
        return (trueOffset-leadingOffset) * -1.0
    }
    
   
    var body: some View {
        GeometryReader { outerGeometry in
            HStack(alignment: .center, spacing: self.tilePadding)  {
                /// building items into HStack
                ForEach(0..<self.items.count) { index in
                    
                        self.items[index]
                            .scaledToFill()
                    
                }
            }
            .onAppear {
                self.currentScrollOffset = self.offsetForPageIndex(self.activePageIndex)
            }
//            .offset(x: self.stackOffset, y: 0)
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
                    withAnimation(.interpolatingSpring(mass: 0.1, stiffness: 20, damping: 1.5, initialVelocity: 0)){
                        self.activePageIndex = newPageIndex
                        self.currentScrollOffset = self.computeCurrentScrollOffset()
                    }
                }
            )
        }
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
