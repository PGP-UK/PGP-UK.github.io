var PGP;
if (!PGP) {
  PGP = {};
}

(function ($) {

  // Sticky navbar on scroll
  if($('.navbar-sticky').length && $('.main-navigation').length) {
    new Waypoint.Sticky({
      element: $('.navbar-sticky .main-navigation')[0]
    });
  }

  $(window).on('turbolinks:load', function () {
    if($('.waves-effect').length > 0) {
      Waves.init( { duration: 600 } );
    }

    if ($('.scroll-to-top-btn').length > 0) {
      PGP.initScrollToTop('.scroll-to-top-btn');
    }

    PGP.initSmoothScroll('.scroll-to');

    if ($('#conference-slider').length > 0) {
      PGP.initSlider('#conference-slider');
    }
    if ($('.play-btn').length > 0) {
      PGP.initVideoPopup('.play-btn');
    }

    // Scroll Reveal Animations
    $('[data-sr-id]').removeAttr('data-sr-id').removeAttr('style');
    if($('.scrollReveal').length && ! $('html.ie9').length) {
      $('.scrollReveal').parent().css('overflow', 'hidden');
      PGP.sr = ScrollReveal({
        reset: false,
        distance: '32px',
        mobile: true,
        duration: 850,
        scale: 1,
        viewFactor: 0.3,
        easing: 'ease-in-out'
      });

      PGP.sr.reveal('.sr-top', { origin: 'top' });
      PGP.sr.reveal('.sr-bottom', { origin: 'bottom' });
      PGP.sr.reveal('.sr-left', { origin: 'left' });
      PGP.sr.reveal('.sr-long-left', { origin: 'left', distance: '70px', duration: 1000 });
      PGP.sr.reveal('.sr-right', { origin: 'right' });
      PGP.sr.reveal('.sr-scaleUp', { scale: '0.8' });
      PGP.sr.reveal('.sr-scaleDown', { scale: '1.15' });

      PGP.sr.reveal('.sr-delay-1', { delay: 200 });
      PGP.sr.reveal('.sr-delay-2', { delay: 400 });
      PGP.sr.reveal('.sr-delay-3', { delay: 600 });
      PGP.sr.reveal('.sr-delay-4', { delay: 800 });
      PGP.sr.reveal('.sr-delay-5', { delay: 1000 });
      PGP.sr.reveal('.sr-delay-6', { delay: 1200 });
      PGP.sr.reveal('.sr-delay-7', { delay: 1400 });
      PGP.sr.reveal('.sr-delay-8', { delay: 1600 });
      PGP.sr.reveal('.sr-delay-9', { delay: 1800 });
      PGP.sr.reveal('.sr-delay-10', { delay: 2000 });
      PGP.sr.reveal('.sr-delay-11', { delay: 2200 });
      PGP.sr.reveal('.sr-delay-12', { delay: 2400 });

      PGP.sr.reveal('.sr-ease-in-out-quad', { easing: 'cubic-bezier(0.455,  0.030, 0.515, 0.955)' });
      PGP.sr.reveal('.sr-ease-in-out-cubic', { easing: 'cubic-bezier(0.645,  0.045, 0.355, 1.000)' });
      PGP.sr.reveal('.sr-ease-in-out-quart', { easing: 'cubic-bezier(0.770,  0.000, 0.175, 1.000)' });
      PGP.sr.reveal('.sr-ease-in-out-quint', { easing: 'cubic-bezier(0.860,  0.000, 0.070, 1.000)' });
      PGP.sr.reveal('.sr-ease-in-out-sine', { easing: 'cubic-bezier(0.445,  0.050, 0.550, 0.950)' });
      PGP.sr.reveal('.sr-ease-in-out-expo', { easing: 'cubic-bezier(1.000,  0.000, 0.000, 1.000)' });
      PGP.sr.reveal('.sr-ease-in-out-circ', { easing: 'cubic-bezier(0.785,  0.135, 0.150, 0.860)' });
      PGP.sr.reveal('.sr-ease-in-out-back', { easing: 'cubic-bezier(0.680, -0.550, 0.265, 1.550)' });
    }
  });
})(jQuery);

