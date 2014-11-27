#!/usr/bin/env roseus

(ros::roseus "umbrella-catch")
(load "package://hrpsys_ros_bridge_tutorials/euslisp/hrp2w-interface.l")
(hrp2w-init)
(setq *umb-pos* nil)
(setq *obj-tf* nil)

(defun box-callback (msg)
  (setq boxes (send msg :boxes))
  (when boxes
    (setq maxindex 0)
    (setq maxv 0)
    (setq count 0)
    (dolist (box boxes)
      (setq x (send box :dimensions :x))
      (setq y (send box :dimensions :y))
      (setq z (send box :dimensions :z))
      (if (> (* x y z) maxv)
	  (progn
	    (setq maxindex count)
	    (setq maxv (* x y z))))
      (setq count (+ count 1)))
    (setq *obj-tf* (format nil "/camera_remote/depth_registered/cluster_decomposeroutput~0,2d" maxindex))))

(ros::subscribe "/camera_remote/depth_registered/cluster_decomposer/boxes" jsk_pcl_ros::BoundingBoxArray #'box-callback)

(objects (list *hrp2w*))

(defun detect ()
  (ros::spin-once)
  (when *obj-tf*
    (progn
      (when (send *tfl* :wait-for-transform "CHEST_LINK0" *obj-tf* (ros::time 0) 3)
	(progn
	  (setq *target-co* (send *tfl* :lookup-transform "CHEST_LINK0" *obj-tf* (ros::time 0)))
	  ;; TFで認識されたものの一番最初の場所を，CHEST_LINK0から見た相対座標を持ってくる．
	  (setq *umb-pos* (send *torso-co* :transform *target-co*))
	  (objects (list *hrp2w* *umb-pos*)))))))

(defun reset ()
  (send *hrp2w* :reset-pose)
  (send *ri* :angle-vector (send *hrp2w* :angle-vector) 5000)
  (send *ri* :wait-interpolation)
)

(defun ready ()
  (setq *dest* (send *umb-pos* :copy-worldcoords))
  (send *dest* :translate (float-vector -100 0 0))
  (send *hrp2w* :rarm :inverse-kinematics *dest* :debug-view t :link-list (send *hrp2w* :link-list (send *hrp2w* :rarm :end-coords :parent)))
  (send *ri* :angle-vector (send *hrp2w* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (setq *dest* (send *umb-pos* :copy-worldcoords))
  (send *hrp2w* :rarm :inverse-kinematics *dest* :debug-view t :link-list (send *hrp2w* :link-list (send *hrp2w* :rarm :end-coords :parent)))
  (send *ri* :angle-vector (send *hrp2w* :angle-vector) 5000)
  (send *ri* :wait-interpolation)
)

(defun catch ()
  (hrp2w-start :rarm :grasp :angle -15)
)

(defun up ()
  (setq *dest* (send *umb-pos* :copy-worldcoords))
  (send *dest* :translate (float-vector 0 0 250))
  (send *hrp2w* :rarm :inverse-kinematics *dest* :debug-view t :link-list (send *hrp2w* :link-list (send *hrp2w* :rarm :end-coords :parent)))
  (send *ri* :angle-vector (send *hrp2w* :angle-vector) 5000)
  (send *ri* :wait-interpolation)
  
  (setq *dest* (send *umb-pos* :copy-worldcoords))
  (send *dest* :translate (float-vector 0 0 500))
  (send *hrp2w* :rarm :inverse-kinematics *dest* :debug-view t :link-list (send *hrp2w* :link-list (send *hrp2w* :rarm :end-coords :parent)))
  (send *ri* :angle-vector (send *hrp2w* :angle-vector) 5000)
  (send *ri* :wait-interpolation)
)

(defun back ()
  (setq *dest* (send *umb-pos* :copy-worldcoords))
  (send *dest* :translate (float-vector -200 0 500))
  (send *hrp2w* :rarm :inverse-kinematics *dest* :debug-view t :link-list (send *hrp2w* :link-list (send *hrp2w* :rarm :end-coords :parent)))
  (send *ri* :angle-vector (send *hrp2w* :angle-vector) 5000)
  (send *ri* :wait-interpolation)
  
  (setq *thumb* (send *hrp2w* :rarm :thumb-r :joint-angle))
  (send *hrp2w* :reset-pose)
  (send *hrp2w* :rarm :thumb-r :joint-angle *thumb*)
  (send *ri* :angle-vector (send *hrp2w* :angle-vector) 5000)
  (send *ri* :wait-interpolation)
)