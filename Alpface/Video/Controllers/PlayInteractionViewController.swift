//
//  PlayInteractionViewController.swift
//  Alpface
//
//  Created by swae on 2018/3/12.
//  Copyright © 2018年 alpface. All rights reserved.
//  和PlayVideoViewController配合使用，处理播放器的UI

import UIKit

let ALPplayStatusButtonAlpha: CGFloat = 0.5


@objc(ALPPlayInteractionViewController)
class PlayInteractionViewController: UIViewController {
    
    public var videoItem: VideoItem? {
        didSet {
        }
    }
    
    /// 播放控制器
    open var playerController: PlayVideoViewController?
    
    /// 播放/暂停状态按钮
    fileprivate var playStatusButton: UIButton = {
        let playStatusButton = UIButton(type: .custom)
        playStatusButton.translatesAutoresizingMaskIntoConstraints = false
        playStatusButton.setBackgroundImage(UIImage(named:"icon_pausemusic"), for: .selected)
        playStatusButton.setBackgroundImage(UIImage(named:"icon_playmusic"), for: .normal)
        playStatusButton.isUserInteractionEnabled = false
        playStatusButton.alpha = ALPplayStatusButtonAlpha
        return playStatusButton
    }()
    /// 播放进度: 当视频超过3分钟时才显示进度条，如果视频太短，进度条显示效果不是很好
    fileprivate var progressView: OSProgressView = {
        let progressView = OSProgressView(frame: .zero)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = UIColor.white
        progressView.trackTintColor = UIColor.lightGray.withAlphaComponent(0.6)
        return progressView
    }()
    
    /// 加载指示器
    fileprivate lazy var indicator : UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    /// 显示播放时间
    fileprivate lazy var timeLabel: UILabel = {
        let timeLabel = UILabel(frame: .zero)
        timeLabel.font = UIFont.systemFont(ofSize: 12.0)
        timeLabel.textColor = UIColor.red
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        return timeLabel
    }()
    
    /// 显示视频详细信息的视图
    fileprivate lazy var detailView: FeedVideoDetailView = {
        let view = FeedVideoDetailView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    convenience init(playerController: PlayVideoViewController) {
        self.init()
        self.playerController = playerController
        playerController.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupUI()
        
        // 添加单击轻怕手势
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(tap:)))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.numberOfTouchesRequired  = 1
        view.addGestureRecognizer(singleTapGesture)
        
        // 添加双击轻拍手势
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(tap:)))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.numberOfTouchesRequired = 1
        view.addGestureRecognizer(doubleTapGesture)
        
        // 解决单击和双击手势冲突，设置只有双击手势失败时才触发单击手势
        singleTapGesture.require(toFail: doubleTapGesture)
        
    }
}

// MARK: - Actions
extension PlayInteractionViewController {
    /// 单击 播放/暂停
    @objc fileprivate func handleSingleTap(tap: UITapGestureRecognizer) {
        if tap.state == .ended {
            guard let playerController = playerController else { return }
            if playerController.state == .playing {
                playerController.pause()
            }
            else {
                playerController.play()
            }
            // 播放按钮出现时回弹下
            UIView.animate(withDuration: 0.1, animations: {
                self.playStatusButton.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
                self.playStatusButton.alpha = ALPplayStatusButtonAlpha - 0.3
            }) { (finished) in
                self.playStatusButton.transform = CGAffineTransform.init(scaleX: 1.1, y: 1.1)
                self.playStatusButton.alpha = ALPplayStatusButtonAlpha - 0.2
                UIView.animate(withDuration: 0.3, animations: {
                    self.playStatusButton.transform = CGAffineTransform.init(scaleX: 1.0, y: 1.0)
                    self.playStatusButton.alpha = ALPplayStatusButtonAlpha
                    UIView.animate(withDuration: 0.1, animations: {
                        self.playStatusButton.layoutIfNeeded()
                        
                    })
                }, completion: { (isFinished) in
                    
                })
            }
        }
    }
    
    /// 双击 点赞
    @objc fileprivate func handleDoubleTap(tap: UITapGestureRecognizer) {
        HeartAnimation.animation(tapGesture: tap)
    }
}

// MARK: - PlayVideoViewControllerDelegate
extension PlayInteractionViewController : PlayVideoViewControllerDelegate {
    /// 播放进度改变时调用
    func playVideoViewController(didChangePlayerProgress player:PlayVideoViewController, time: String, progress: Float) -> Void {
        self.progressView.progress = CGFloat(progress)
    }
    /// 缓冲进度改变时调用
    func playVideoViewController(didChangebufferedProgress player:PlayVideoViewController, loadedTime: Double, bufferedProgress: Float) -> Void {
        
    }
    /// 播放状态改变时调用
    func playVideoViewController(didChangePlayerState player:PlayVideoViewController, state: PlayerState) -> Void {
        if  state == .paused {
            playStatusButton.isSelected = false
            playStatusButton.isHidden = false
        }
        else if state == .playing || state == .buffering {
            playStatusButton.isHidden = true
            playStatusButton.isSelected = true
            
        }
        else if state == .failure || state == .stopped {
            playStatusButton.isSelected = true
            playStatusButton.isHidden = false
            
        }
        
        if state != .buffering {
            indicator.stopAnimating()
            indicator.isHidden = true
        }
        else {
            indicator.startAnimating()
            indicator.isHidden = false
        }
    }
    /// 播放完毕时调用
    func playVideoViewController(didPlayToEnd player: PlayVideoViewController) -> Void {
        // 播放完毕，重置进度
        progressView.progress = 0.0
    }
}

// MARK: - UI
extension PlayInteractionViewController {
    fileprivate func setupUI() {
        view.addSubview(playStatusButton)
        playStatusButton.widthAnchor.constraint(equalToConstant: 66).isActive = true
        playStatusButton.heightAnchor.constraint(equalToConstant: 66).isActive = true
        playStatusButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        playStatusButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        view.addSubview(progressView)
        progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        progressView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -49.0).isActive = true
        progressView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        
        view.addSubview(timeLabel)
        timeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20.0).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20.0).isActive = true
        
        view.addSubview(indicator)
        indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        view.addSubview(detailView)
        detailView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -50.0).isActive = true
        detailView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0.0).isActive = true
        detailView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0.0).isActive = true
         detailView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.6, constant: 0.0).isActive = true
    }
}
