//
//  SwiftUIView.swift
//  
//
//  Created by Ahmet Bascivan on 15/11/2020.
//

import SwiftUI
import UIKit

/// A paging view that generates user-defined static pages.
@available(iOS 13.0, *)
public struct Pages: View {

    @Binding var currentPage: Int
    var pages: [AnyView]

    var navigationOrientation: UIPageViewController.NavigationOrientation
    var transitionStyle: UIPageViewController.TransitionStyle
    var bounce: Bool
    var wrap: Bool
    var hasControl: Bool
    var pageControl: UIPageControl? = nil
    var controlAlignment: Alignment

    /**
    Creates the paging view that generates user-defined static pages.

    `Pages` can be used as follows:
       ```
           struct WelcomeView: View {

               @State var index: Int = 0

               var body: some View {
                   Pages(currentPage: $index) {
                        Text("Welcome! This is Page 1")
                        Text("This is Page 2")
                        Text("...and this is Page 3")
                   }
               }
           }
       ```

       - Parameters:
           - navigationOrientation: Whether to paginate horizontally or vertically.
           - transitionStyle: Whether to perform a page curl or a scroll effect on page turn.
           - bounce: Whether to bounce back when a user tries to scroll past all the pages.
           - wrap: A flag indicating whether to wrap the pages circularly when the user scrolls past the beginning or end.
           - hasControl: Whether to display a page control or not.
           - control: A user defined page control.
           - controlAlignment: What position to put the page control.
           - pages: A function builder `PagesBuilder` that will put the views defined by the user on a list.
    */
    public init(
        currentPage: Binding<Int>,
        navigationOrientation: UIPageViewController.NavigationOrientation = .horizontal,
        transitionStyle: UIPageViewController.TransitionStyle = .scroll,
        bounce: Bool = true,
        wrap: Bool = false,
        hasControl: Bool = true,
        control: UIPageControl? = nil,
        controlAlignment: Alignment = .bottom,
        @PagesBuilder pages: () -> [AnyView]
    ) {
        self.navigationOrientation = navigationOrientation
        self.transitionStyle = transitionStyle
        self.bounce = bounce
        self.wrap = wrap
        self.hasControl = hasControl
        self.pageControl = control
        self.controlAlignment = controlAlignment
        self.pages = pages()
        self._currentPage = currentPage
    }

    public var body: some View {
        ZStack(alignment: self.controlAlignment) {
            PageViewController(
                currentPage: $currentPage,
                navigationOrientation: navigationOrientation,
                transitionStyle: transitionStyle,
                bounce: bounce,
                wrap: wrap,
                controllers: pages.map {
                    let h = UIHostingController(rootView: $0)
                    h.view.backgroundColor = .clear
                    return h
                }
            )
            if self.hasControl {
                PageControl(
                    numberOfPages: pages.count,
                    pageControl: pageControl,
                    currentPage: $currentPage
                ).padding()
            }
        }
    }
}
