From stdpp Require Import base list.
From Autosubst Require Export Autosubst.
Require Export Utf8_core.

From fae_gtlc_mu.cast_calculus Require Export types.

Inductive alternative_consistency_pre (A : list (type * type)) : type -> type -> Type :=
  (** ground and star *)
  (* downcasting from star to ground *)
  | consp_StarTGround τG
      (G : Ground τG) :
      alternative_consistency_pre A TUnknown τG
  (* upcasting from ground to star *)
  | consp_TGroundStar τG
      (G : Ground τG) :
      alternative_consistency_pre A τG TUnknown
  (** factorization through ground types, first direction *)
  | consp_TauGroundProd (τ1 τ2 : type)
      (pτnG : τ1 ≠ TUnknown ∨ τ2 ≠ TUnknown)
      (pC1 : alternative_consistency_pre A τ1 TUnknown)
      (pC2 : alternative_consistency_pre A τ2 TUnknown) :
      alternative_consistency_pre A (TProd τ1 τ2) TUnknown 
  | consp_TauGroundSum (τ1 τ2 : type)
      (pτnG : τ1 ≠ TUnknown ∨ τ2 ≠ TUnknown)
      (pC1 : alternative_consistency_pre A τ1 TUnknown)
      (pC2 : alternative_consistency_pre A τ2 TUnknown) :
      alternative_consistency_pre A (TSum τ1 τ2) TUnknown 
  | consp_TauGroundArrow (τ1 τ2 : type)
      (pτnG : τ1 ≠ TUnknown ∨ τ2 ≠ TUnknown)
      (pC1 : alternative_consistency_pre A TUnknown τ1)
      (pC2 : alternative_consistency_pre A τ2 TUnknown) :
      alternative_consistency_pre A (TArrow τ1 τ2) TUnknown
  | consp_TauGroundRecUseCall (τb : type) i
      (pτnG : τb ≠ TUnknown)
      (pμτlμtrinA : A !! i = Some (TRec τb, TRec TUnknown)) :
      alternative_consistency_pre A (TRec τb) TUnknown
  | consp_TauGroundRecExposeCall (τb : type)
      (pτnG : τb ≠ TUnknown)
      (pμτlμτrnotA : (TRec τb, TRec TUnknown) ∉ A)
      (pUnfτlUnfτr : alternative_consistency_pre ((TRec τb, TRec TUnknown) :: A) τb.[TRec τb/] TUnknown) :
      alternative_consistency_pre A (TRec τb) TUnknown
  (** factorization through ground types, second direction *)
  | consp_GroundProdTau (τ1 τ2 : type)
      (pτnG : τ1 ≠ TUnknown ∨ τ2 ≠ TUnknown)
      (pC1 : alternative_consistency_pre A TUnknown τ1)
      (pC2 : alternative_consistency_pre A TUnknown τ2) :
      alternative_consistency_pre A TUnknown (TProd τ1 τ2)
    | consp_GroundSumTau (τ1 τ2 : type)
      (pτnG : τ1 ≠ TUnknown ∨ τ2 ≠ TUnknown)
      (pC1 : alternative_consistency_pre A TUnknown τ1)
      (pC2 : alternative_consistency_pre A TUnknown τ2) :
      alternative_consistency_pre A TUnknown (TSum τ1 τ2)
    | consp_GroundArrowTau (τ1 τ2 : type)
      (pτnG : τ1 ≠ TUnknown ∨ τ2 ≠ TUnknown)
      (pC1 : alternative_consistency_pre A τ1 TUnknown)
      (pC2 : alternative_consistency_pre A TUnknown τ2) :
      alternative_consistency_pre A TUnknown (TArrow τ1 τ2)
  | consp_GroundRecTauUseCall (τb : type) i
      (pτnG : τb ≠ TUnknown)
      (pμτlμtrinA : A !! i = Some (TRec TUnknown, TRec τb)) :
      alternative_consistency_pre A TUnknown (TRec τb)
  | consp_GroundRecTauExposeCall (τb : type)
      (pτnG : τb ≠ TUnknown)
      (pμτlμτrnotA : (TRec TUnknown , TRec τb) ∉ A)
      (pUnfτlUnfτr : alternative_consistency_pre ((TRec TUnknown, TRec τb) :: A) TUnknown τb.[TRec τb/]) :
      alternative_consistency_pre A TUnknown (TRec τb)
  (** identiy casts between Base and TUnknown *)
  | consp_BaseBase :
      alternative_consistency_pre A TUnit TUnit
  | consp_StarStar :
      alternative_consistency_pre A TUnknown TUnknown
  (** between types of same structure *)
  | consp_TProdTProd τ1 τ1' τ2 τ2'
      (pCons31 : alternative_consistency_pre A τ1 τ1')
      (pCons24 : alternative_consistency_pre A τ2 τ2') :
      alternative_consistency_pre A (TProd τ1 τ2) (TProd τ1' τ2')
  | consp_TSumTSum τ1 τ1' τ2 τ2'
      (pCons31 : alternative_consistency_pre A τ1 τ1')
      (pCons24 : alternative_consistency_pre A τ2 τ2') :
      alternative_consistency_pre A (TSum τ1 τ2) (TSum τ1' τ2')
  | consp_TArrowTArrow τ1 τ1' τ2 τ2'
      (pCons31 : alternative_consistency_pre A τ1' τ1)
      (pCons24 : alternative_consistency_pre A τ2 τ2') :
      alternative_consistency_pre A (TArrow τ1 τ2) (TArrow τ1' τ2')
  (** exposing recursive calls *)
  | consp_TRecTRecExposeCall τl τr
      (pμτlμτrnotA : (TRec τl, TRec τr) ∉ A)
      (pUnfτlUnfτr : alternative_consistency_pre ((TRec τl, TRec τr) :: A) τl.[TRec τl/] τr.[TRec τr/]) :
      alternative_consistency_pre A (TRec τl) (TRec τr)
  (** using recursive calls *)
  | consp_TRecTRecUseCall τl τr i
      (pμτlμtrinA : A !! i = Some (TRec τl, TRec τr)) :
      alternative_consistency_pre A (TRec τl) (TRec τr).
