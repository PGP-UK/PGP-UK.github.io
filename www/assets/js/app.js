var PGP;
if (!PGP) {
  PGP = {};
}

PGP.initSlider = function(id) {
  $(id).masterslider({
    width: 1920,
    height: 500,
    space: 0,
    layout: 'fillwidth',
    autoHeight: true,
    loop: true,
    view: 'flow',
    autoplay: true,
    controls: {
      arrows: { hideUnder: 800 },
      bullets: { autohide: false },
      timebar: { color: 'rgba(255,255,255,.5)', align: 'top' }
    }
  });
}

PGP.initVideoPopup = function(id) {
  $(id).magnificPopup({
    type: 'iframe',
    mainClass: 'mfp-fade',
    removalDelay: 500
  });
}

PGP.initScrollToTop = function(id) {
  $(window).on('scroll', function() {
    if ($(window).scrollTop() > 600) {
      $(id).addClass('visible');
    } else {
      $(id).removeClass('visible');
    }
  });
  $(document).on('click', id, function(e) {
    e.preventDefault();
    $('html').velocity('scroll', {offset: 0,
      duration: 1000,
      easing: 'easeOutExpo',
      mobileHA: false
    });
  });
}

PGP.initSmoothScroll = function(id) {
  $(document).on('click', id, function(event) {
    var $elemOffsetTop = $(this).data('offset-top');
    if ($elemOffsetTop == undefined) {
      $elemOffsetTop = 40;
    }
    $('html').velocity('scroll', {
      offset: $(this.hash).offset().top - $elemOffsetTop,
      duration: 1000,
      easing: 'easeOutExpo',
      mobileHA: false
    });
    event.preventDefault();
  });
}

// make the profile boxes on the about page the same height
PGP.equalizeMainSectionText = function () {
  PGP.equalizeDivHeight('.main_section_text');
  $(window).resize(function () {
    $('.main_section_text').css('height', 'auto');
    PGP.equalizeDivHeight('.main_section_text');
  });
};

PGP.equalizeDivHeight = function (div) {
  if ($(div).length === 0) return;
  var maxHeight = 0;
  $(div).each(function () {
    if ($(this).height() > maxHeight) {
      maxHeight = $(this).height();
    }
  });
  $(div).css('height', maxHeight);
};

// Toggle Mobile Navigation
PGP.toggleNavBar = function() {
  $('.navbar .nav-toggle').toggleClass('active');
  $('.navbar .main-navigation').toggleClass('expanded');
  $('.navbar .toolbar').toggleClass('expanded');
  $('.navbar .mobile-socials').toggleClass('expanded');
};

if (!$('.navbar .nav-toggle').hasClass('initialized')) {
  $(document).on('click', '.navbar .nav-toggle', function() {
    // console.log('toggle Navbar');
    // setTimeout(function() {
      PGP.toggleNavBar();
    // }, 500);
  });
  $('.navbar .nav-toggle:not(.initialized)').addClass('initialized');
}

document.addEventListener('turbolinks:before-render', function(event) {
  FontAwesome.dom.i2svg({
    node: event.data.newBody
  });
});

// Tooltips
$('[data-toggle="tooltip"]').tooltip();

//// FULL RELOAD WHEN JS ERROR

// If a JS error occurs in the browser, the app can be left in
// a bad state depending on how badly the JS console decides to crash.
// Subsequent errors can continue to be triggered because the page is
// never reloaded - so force a full page reload on the next page visit.
PGP.jsErrorHasOccurred = false

window.onerror = function () {
  PGP.jsErrorHasOccurred = true;
}

document.addEventListener('turbolinks:before-visit', function(event) {
  if (PGP.jsErrorHasOccurred == true) {
    event.preventDefault(); // Cancel the turbolinks request
    window.location.href = event.data.url; // Do a regular page visit to clear the JS console
  }
});

// RESET DT OBJECTS BEFORE CACHE
PGP.resetDatatables = function () {
  dataTable = $($.fn.dataTable.tables(true)).DataTable();
  if (dataTable != null) {
    dataTable.destroy();
  }
  dataTable = null;
  if (PGP.datatable != null) {
    PGP.datatable.destroy();
  }
  PGP.datatable = undefined
};

document.addEventListener('turbolinks:before-cache', function() {
  PGP.resetDatatables();
});
