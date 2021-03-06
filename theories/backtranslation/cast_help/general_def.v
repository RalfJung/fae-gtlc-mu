From fae_gtlc_mu.stlc_mu Require Export typing lang types_lemmas.
From fae_gtlc_mu.cast_calculus Require Export types types_lemmas.
From fae_gtlc_mu.backtranslation Require Export alternative_consistency types_lemmas.
From fae_gtlc_mu.backtranslation.cast_help Require Export universe embed extract between factorize identity.
From Coq Require Export List.

(** This file brings together the static functions (defined in embed.v, extract.v, between.v, factorize.v and identity.v),
    to define the backtranslation of a cast (between an arbitrary pair of two consistent types) by recursion on the alternative consistency relation. (figure 9 in paper) *)

Fixpoint 𝓕 {A : list (types.type * types.type)} {τi τf : cast_calculus.types.type} (P : alternative_consistency A τi τf) : expr :=
  match P with
  | atomic_Unknown_Ground _ τG G => extract τG G
  | atomic_Ground_Unknown _ τG G => embed τG G
  | factorUp_Ground _ τ τG pτnG pτnStar pτSτG pτConsτG pτGConsStar =>
    factorization (𝓕 pτConsτG) (𝓕 pτGConsStar)
  | factorDown_Ground _ τ τG pτnG pτnStar pτSτG pStarConsτG pτGConsτ =>
    factorization (𝓕 pStarConsτG) (𝓕 pτGConsτ)
  | atomic_Base _ => identity
  | atomic_Unknown _ => identity
  | throughSum _ τ1 τ1' τ2 τ2' pCons1 pCons2 =>
    between_TSum
      (𝓕 pCons1)
      (𝓕 pCons2)
  | throughProd _ τ1 τ1' τ2 τ2' pCons1 pCons2 =>
    between_TProd
      (𝓕 pCons1)
      (𝓕 pCons2)
  | throughArrow _ τ1 τ2 τ3 τ4 pCons31 pCons24 =>
    between_TArrow
      (𝓕 pCons31)
      (𝓕 pCons24)
  | exposeRecursiveCAll _ τl τr pμτlμτrnotA pUnfτlUnfτr =>
    between_TRec
      (𝓕 pUnfτlUnfτr)
  | atomic_UseRecursion _ τl τr i pμτlμtrinA => Var i
  end.

(* A pair in our list A, say (τ1, τ2), will correspond in the backtranslation to a static type <<τ1>> → <<τ2>> *)

Definition back_pair (p : cast_calculus.types.type * cast_calculus.types.type) : stlc_mu.types.type :=
  stlc_mu.types.TArrow <<p.1>> <<p.2>>.

(* Proving well-typedness of our backtranslation function *)
(* We restrict ourselves to the meaningful (i.e. closed) types here *)
Lemma 𝓕_typed (A : list (cast_calculus.types.type * cast_calculus.types.type)) (pA : Forall (fun p => Closed p.1 ∧ Closed p.2) A)
      (τi τf : cast_calculus.types.type) (pτi : Closed τi) (pτf : Closed τf) (pτiConsτf : alternative_consistency A τi τf) :
  (map back_pair A) ⊢ₛ (𝓕 pτiConsτf) : (stlc_mu.types.TArrow <<τi>> <<τf>>).
Proof.
  induction pτiConsτf; simpl.
  - apply extract_typed.
  - apply embed_typed.
  - eapply factorization_typed.
    apply IHpτiConsτf1; auto. by apply Ground_closed; eapply get_shape_is_ground.
    apply IHpτiConsτf2; auto. by apply Ground_closed; eapply get_shape_is_ground.
  - eapply factorization_typed.
    apply IHpτiConsτf1; auto. by apply Ground_closed; eapply get_shape_is_ground.
    apply IHpτiConsτf2; auto. by apply Ground_closed; eapply get_shape_is_ground.
  - apply identity_typed. apply stlc_mu.types_lemmas.TUnit_Closed.
  - apply identity_typed. apply Universe_closed.
  - apply between_TSum_typed.
    apply IHpτiConsτf1; auto; by eapply (cast_calculus.types_lemmas.TSum_closed1).
    apply IHpτiConsτf2; auto; by eapply (cast_calculus.types_lemmas.TSum_closed2).
  - apply between_TProd_typed.
    apply IHpτiConsτf1; auto; by eapply (cast_calculus.types_lemmas.TProd_closed1).
    apply IHpτiConsτf2; auto; by eapply (cast_calculus.types_lemmas.TProd_closed2).
  - apply between_TArrow_typed.
    apply IHpτiConsτf1; auto; by eapply (cast_calculus.types_lemmas.TArrow_closed1).
    apply IHpτiConsτf2; auto; by eapply (cast_calculus.types_lemmas.TArrow_closed2).
  - apply between_TRec_typed.
    rewrite map_cons in IHpτiConsτf.
    repeat rewrite back_unfold_comm in IHpτiConsτf.
    apply IHpτiConsτf; auto; by apply cast_calculus.types_lemmas.TRec_closed_unfold.
  - apply Var_typed.
    cut (Closed <<(cast_calculus.types.TArrow (cast_calculus.types.TRec τl) (cast_calculus.types.TRec τr))>>). by simpl.
    by apply back_closed, cast_calculus.types_lemmas.TArrow_closed.
    rewrite list_lookup_fmap. by rewrite pμτlμtrinA.
Qed.

(* A shorthand notation to substitute out the open variables by a list of values fs *)
Definition 𝓕c {A} {τi τf} (pC : alternative_consistency A τi τf) (fs : list val) : stlc_mu.lang.expr :=
  (𝓕 pC).[stlc_mu.typing_lemmas.env_subst fs].
