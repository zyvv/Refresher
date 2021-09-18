//
//  Refresher.swift
//  Refresher
//
//  Created by 张洋威 on 2021/6/24.
//

import UIKit

public extension Refresher {
    
    typealias RefresherAction = () -> Void
    
    enum Position {
        case top, bottom
    }

    enum State: Equatable {
        case idle
        case pulling(progress: CGFloat)
        case willRefresh(overOffset: CGFloat)
        case refreshing
        
        public static func ==(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.pulling, .pulling): return true
            case ( .willRefresh, .willRefresh): return true
            case (.refreshing, .refreshing): return true
            default: return false
            }
        }
        
        public static func ===(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.pulling(let lshProgress), .pulling(let rshProgress)):
                return lshProgress == rshProgress
            case (.willRefresh(let lshOverOffset), .willRefresh(let rshOverOffset)):
                return lshOverOffset == rshOverOffset
            default:
                return lhs == rhs
            }
        }
    }
    
}

public final class Refresher: UIView {

    private var scrollViewOriginalInset: UIEdgeInsets = .zero
    private weak var scrollView: UIScrollView?
    private var panGesture: UIPanGestureRecognizer?

    private var contentOffsetObservation: NSKeyValueObservation?
    private var contentSizeObservation: NSKeyValueObservation?
    private var panGestureStateObservation: NSKeyValueObservation?
        
    private var topInsetDelta: CGFloat = 0
    private var lastBottomDelta: CGFloat = 0
    
    
    private let animateView: Refreshable
    private var noMoreDataView: UIView?
    private let action: RefresherAction
    private var codeRefreshing: Bool = false
    
    public internal(set) var position: Position
    
    public var isEnable: Bool = true {
        didSet {
            if isEnable && position == .bottom {
                removeNoMoreDataView()
            }
        }
    }
    
    public var isRefreshing: Bool {
        state == .refreshing
    }

    private(set) var state: State = .idle {
        didSet {
            if oldValue === state { return }
            animateView.animate(state)
            if state == .idle {
                if oldValue != .refreshing {  return }
                endAction()
            } else if state == .refreshing {
                refreshingAction()
            }
        }
    }
    
    public init(_ animateView: Refreshable = DefaultAnimateView(),
         position: Position = .top,
         height: CGFloat = 52,
         action: @escaping RefresherAction) {
        self.animateView = animateView
        self.position = position
        self.action = action
        
        super.init(frame: .zero)
        self.frame.size.height = height
        self.prepare()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeObservers()
    }
    
    public func beginRefreshing() {
        if !isEnable { return }
        if state == .refreshing { return }
        codeRefreshing = true
        DispatchQueue.main.async {
            self.state = .pulling(progress: 1)
            self.state = .refreshing
        }
    }
    
    public func endRefreshing(_ noMoreDataView: UIView? = nil) {
        self.noMoreDataView = noMoreDataView
        codeRefreshing = false
        DispatchQueue.main.async {
            self.setupNoMoreDataView()
            self.state = .idle
        }
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        guard let newSuperview = newSuperview as? UIScrollView else {
            return
        }
        removeObservers()
        scrollView = newSuperview
        newSuperview.alwaysBounceVertical = true
        setupFrame()
        scrollViewOriginalInset = newSuperview.adjustedContentInset
        
        addObservers()
    }
    
    private func prepare() {
        autoresizingMask = .flexibleWidth
        backgroundColor = .clear
        addSubview(animateView)
        animateView.frame = bounds
        animateView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    private func setupFrame() {
        guard let scrollView = scrollView else { return }
        frame.size.width = scrollView.frame.width
        frame.origin.x = -scrollView.leftInset
        frame.origin.y = position == .top ? -frame.height : scrollView.contentHeight
    }
    
    private func removeNoMoreDataView() {
        DispatchQueue.main.async {
            self.noMoreDataView?.removeFromSuperview()
            self.noMoreDataView = nil
            self.animateView.isHidden = false
        }
    }
    
    private func setupNoMoreDataView() {
        guard let noMoreDataView = noMoreDataView,
                        position == .bottom else { return }
        isEnable = false
        
        noMoreDataView.alpha = 0
        noMoreDataView.frame.size.width = frame.width
        if noMoreDataView.frame.height <= 0 {
            noMoreDataView.frame.size.height = frame.height
        }
        noMoreDataView.autoresizingMask = [.flexibleWidth]
        addSubview(noMoreDataView)
        
        UIView.animate(withDuration: 0.1) {
            noMoreDataView.alpha = 1
            self.animateView.alpha = 0
        } completion: { _ in
            self.animateView.isHidden = true
            self.animateView.alpha = 1
        }
    }
    
    private func resetInset() {
        guard let scrollView = scrollView else { return }
        let originalInsetTop = scrollViewOriginalInset.top
        
        var topInset = max(-scrollView.offsetY, originalInsetTop)
        topInset = min(frame.height + originalInsetTop, topInset)
                
        topInsetDelta = originalInsetTop - topInset
        
        if scrollView.topInset != topInset {
            scrollView.topInset = topInset
        }
    }
    
    private func addObservers() {
        contentOffsetObservation = scrollView?.observe(\.contentOffset, options: [.old, .new]) { [weak self] scrollView, change in
            guard scrollView.isUserInteractionEnabled else { return }
            self?.scrollViewContentOffsetDidChange(change)
        }
        contentSizeObservation = scrollView?.observe(\.contentSize, options: [.old, .new]) { [weak self] scrollView, change in
            guard scrollView.isUserInteractionEnabled else { return }
            self?.scrollViewContentSizeDidChange(change)
        }
        
        panGesture = scrollView?.panGestureRecognizer
        panGestureStateObservation = panGesture?.observe(\.state, options: [.old, .new]) { [weak self] _, change in
            self?.scrollViewPanGestureStateDidChange(change)
        }
    }
    
    private func removeObservers() {
        contentOffsetObservation?.invalidate()
        contentOffsetObservation = nil
        contentSizeObservation?.invalidate()
        contentSizeObservation = nil
        panGestureStateObservation?.invalidate()
        panGestureStateObservation = nil
        panGesture = nil
    }
    
    private func topRefresherContentOffsetChangeAction() {
        guard let scrollView = scrollView else { return }
        if state == .refreshing {
            resetInset()
            return
        }
        scrollViewOriginalInset = scrollView.inset
        
        let offsetY = scrollView.offsetY
        let appearOffsetY = getAppearOffsetY()
        
        if offsetY > appearOffsetY { return }
        
        let normal2pullingOffsetY = appearOffsetY - frame.height
        let pullingPercent = (appearOffsetY - offsetY) / frame.height

        if scrollView.isDragging {
            if (state == .idle || state == .pulling(progress: -1)) && offsetY >= normal2pullingOffsetY {
                state = .pulling(progress: min(pullingPercent, 1.0))
            } else if (state == .pulling(progress: 1.0) || state == .willRefresh(overOffset: -1)) && offsetY < normal2pullingOffsetY {
                if state == .pulling(progress: 1.0) {
                    state = .pulling(progress: 1.0)
                }
                state = .willRefresh(overOffset: normal2pullingOffsetY - offsetY)
            } else if state == .willRefresh(overOffset: -1) && offsetY >= normal2pullingOffsetY {
                state = .pulling(progress: min(pullingPercent, 1.0))
            }
        } else if state == .willRefresh(overOffset: -1) {
            state = .refreshing
        }
    }
    
    private func bottomRefresherContentOffsetChangeAction() {
        guard let scrollView = scrollView else { return }
        if state == .refreshing {
            return
        }
        scrollViewOriginalInset = scrollView.inset
        let offsetY = scrollView.offsetY
        let appearOffsetY = getAppearOffsetY()
                
        if offsetY <= appearOffsetY { return }
        
        let normal2pullingOffsetY = appearOffsetY + frame.height
        let pullingPercent = (offsetY - appearOffsetY) / frame.height

        if scrollView.isDragging {
            if (state == .idle || state == .pulling(progress: -1)) && offsetY < normal2pullingOffsetY {
                state = .pulling(progress: min(pullingPercent, 1.0))
            } else if (state == .pulling(progress: 1.0) || state == .willRefresh(overOffset: -1)) && offsetY >= normal2pullingOffsetY {
                if state == .pulling(progress: 1.0) {
                    state = .pulling(progress: 1.0)
                }
                state = .willRefresh(overOffset: offsetY - normal2pullingOffsetY)
            } else if state == .willRefresh(overOffset: -1) && offsetY < normal2pullingOffsetY {
                state = .pulling(progress: min(pullingPercent, 1.0))
            }
        } else if state == .willRefresh(overOffset: -1) {
            state = .refreshing
        }
    }
        
    private func refreshingAction() {
        guard let scrollView = scrollView else { return }
        guard scrollView.panGestureRecognizer.state != .cancelled else {
            self.action()
            return
        }
        UIView.animate(withDuration: 0.25) {
            if self.position == .top {
                let top = self.scrollViewOriginalInset.top + self.frame.height
                scrollView.topInset = top
                var offset = scrollView.contentOffset
                offset.y = -top
                scrollView.setContentOffset(offset, animated: false)
            } else if !self.codeRefreshing {
                var bottom = self.frame.height + self.scrollViewOriginalInset.bottom
                let deltaHeight = self.heightForContentBreakView()
                if deltaHeight < 0 {
                    bottom -= deltaHeight
                }
                self.lastBottomDelta = bottom - scrollView.bottomInset
                scrollView.bottomInset = bottom
                var offset = scrollView.contentOffset
                offset.y = self.getAppearOffsetY() + self.frame.height
                scrollView.setContentOffset(offset, animated: false)
            }
        } completion: { _ in
            self.action()
        }
    }
    
    private func endAction() {
        guard let scrollView = scrollView else { return }
        UIView.animate(withDuration: 0.35) {
            if self.position == .top {
                scrollView.topInset += self.topInsetDelta
            } else if !self.codeRefreshing {
                self.lastBottomDelta = self.lastBottomDelta - (self.noMoreDataView?.frame.height ?? 0)
                scrollView.bottomInset -= self.lastBottomDelta
            }
        }
    }
            
    private func scrollViewContentOffsetDidChange(_ change: NSKeyValueObservedChange<CGPoint>?) {
        if !isEnable { return }
        if position == .top {
            topRefresherContentOffsetChangeAction()
        } else {
            bottomRefresherContentOffsetChangeAction()
        }
    }
    
    private func scrollViewContentSizeDidChange(_ change: NSKeyValueObservedChange<CGSize>?) {
        guard let scrollView = scrollView else { return }
        guard position == .bottom else { return }
        frame.origin.y = scrollView.contentHeight
    }
    
    private func scrollViewPanGestureStateDidChange(_ change: NSKeyValueObservedChange<UIPanGestureRecognizer.State>?) {
        if position == .top,
           panGesture?.state == .ended,
           state == .pulling(progress: -1) {
            state = .idle
        }
    }
    
    private func heightForContentBreakView() -> CGFloat {
        guard let scrollView = scrollView else { return 0 }
        let h = scrollView.frame.height - scrollViewOriginalInset.bottom - scrollViewOriginalInset.top
        return scrollView.contentSize.height - h
    }
    
    private func getAppearOffsetY() -> CGFloat {
        if position == .bottom {
            let deltaHeight = heightForContentBreakView()
            if deltaHeight > 0 {
                return deltaHeight - scrollViewOriginalInset.top
            }
        }
        return -scrollViewOriginalInset.top
    }
}
