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
        case rebounding(progress: CGFloat)
        
        public static func ==(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.pulling, .pulling): return true
            case ( .willRefresh, .willRefresh): return true
            case (.refreshing, .refreshing): return true
            case (.rebounding, rebounding): return true
            default: return false
            }
        }
        
        public static func ===(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.pulling(let lshProgress), .pulling(let rshProgress)):
                return lshProgress == rshProgress
            case (.willRefresh(let lshOverOffset), .willRefresh(let rshOverOffset)):
                return lshOverOffset == rshOverOffset
            case (.rebounding(let lshProgress), .rebounding(let rshProgress)):
                return lshProgress == rshProgress
            default:
                return lhs == rhs
            }
        }
    }
    
}

public final class Refresher: UIView {

    private var scrollViewOriginalInset: UIEdgeInsets = .zero
    private weak var scrollView: UIScrollView!
    private var panGesture: UIPanGestureRecognizer?

    private var contentOffsetObservation: NSKeyValueObservation?
    private var contentSizeObservation: NSKeyValueObservation?
    private var panGestureStateObservation: NSKeyValueObservation?
    
    private var displayLink: CADisplayLink?
    
    private var reboundingY: CGFloat = 0
    private var topInsetDelta: CGFloat = 0
    private var lastBottomDelta: CGFloat = 0
    
    
    private let animateView: Refreshable
    private var noMoreDataView: UIView?
    private let action: RefresherAction
    
    internal var position: Position
    
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
            if state == .idle || state == .rebounding(progress: -1) {
                if oldValue != .refreshing {  return }
                endAction()
            } else if state == .refreshing {
                refreshingAction()
            }
        }
    }
    
    init(_ animateView: Refreshable = DefaultAnimateView(),
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
        DispatchQueue.main.async {
            self.state = .pulling(progress: 1)
            self.state = .refreshing
        }
    }
    
    public func endRefreshing(_ noMoreDataView: UIView? = nil) {
        self.noMoreDataView = noMoreDataView
        DispatchQueue.main.async {
            self.setupNoMoreDataView()
            self.state = .rebounding(progress: 0)
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
        
        panGesture = scrollView.panGestureRecognizer
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
        if state == .refreshing {
            return
        }
        scrollViewOriginalInset = scrollView.inset
        let offsetY = scrollView.offsetY
        let appearOffsetY = getAppearOffsetY()
        if offsetY <= appearOffsetY { return }
        if state == .idle {
            state = .pulling(progress: 1)
            state = .refreshing
        }
    }
        
    private func refreshingAction() {
        UIView.animate(withDuration: 0.25) {
            if self.position == .top {
                guard self.scrollView.panGestureRecognizer.state != .cancelled else {
                    self.action()
                    return
                }
                let top = self.scrollViewOriginalInset.top + self.frame.height
                self.scrollView.topInset = top
                var offset = self.scrollView.contentOffset
                offset.y = -top
                self.scrollView.setContentOffset(offset, animated: false)
            } else {
                var bottom = self.frame.height + self.scrollViewOriginalInset.bottom
                let deltaHeight = self.heightForContentBreakView()
                if deltaHeight < 0 {
                    bottom -= deltaHeight
                }
                self.lastBottomDelta = bottom - self.scrollView.bottomInset
                self.scrollView.bottomInset = bottom
                self.scrollView.offsetY = self.getAppearOffsetY() + self.frame.height
            }
        } completion: { _ in
            self.action()
        }            
    }
    
    private func endAction() {
        UIView.animate(withDuration: 0.35) {
            if self.position == .top {
                self.scrollView.topInset += self.topInsetDelta
            } else {
                self.lastBottomDelta = self.lastBottomDelta - (self.noMoreDataView?.frame.height ?? 0)
                self.reboundingY = self.scrollView.bounds.origin.y
                self.scrollView.bottomInset -= self.lastBottomDelta
                
            }
        } completion: { _ in
            self.stopDisplayLink()
            self.state = .idle
        }
        startDisplayLink()
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
    
    private func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        displayLink?.add(to: RunLoop.current, forMode: .common)
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func handleDisplayLink(_ displayLink: CADisplayLink) {
        guard let presentation = scrollView.layer.presentation() else { return }
        var reboundingPercent: CGFloat = 0.0
        if position == .top {
            reboundingPercent = (scrollView.topInset - topInsetDelta + presentation.bounds.origin.y) / -self.topInsetDelta
        } else {
            reboundingPercent = (reboundingY - presentation.bounds.origin.y) / lastBottomDelta
        }
        state = .rebounding(progress: reboundingPercent)
    }
}
